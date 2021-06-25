function interform(directory)
%INTERFORM refactors the Fortran files in directory into the "intersection
% form" and save them in outputdir under directory.
% See http://fortranwiki.org/fortran/show/Continuation+lines for details.
%
% Coded by Zaikun Zhang in August, 2020.

% Output directory
outputdir = 'intersection_form';

% Do not perform refactoring in these subdirectories (if exist)
ignoredir = {'original', 'backup', 'intersection_form', 'trash', 'test', 'results', 'test_data'};

% Ignore the following files
ignorefiles = {'calfun__genmod.f90', 'mexfunction__genmod.f90', 'test.f'};

% "directory" can be given by a full path or a path relative to the
% current directory. The following lines get its full path.
if nargin < 1
    directory = cd();  % When "directory" is not given, we default it to the current directory
end
origdir = cd();
cd(directory);
inputdir = cd();  % Full path of the given directory, which is the current directory now.
cd(origdir);
% Revise ignoredir accoridng to inputdir
[~, inputdirname]  = fileparts(inputdir);
if ~strcmp(inputdirname, 'mex_gateways')
    ignoredir = [ignoredir, 'classical'];
end

outputdir = fullfile(inputdir, outputdir);  % Full path of the output directory.
if exist(outputdir, 'dir')
    rmdir(outputdir, 's');  % Every time we run this script, the content in outputdir is rebuilt
end
mkdir(outputdir);  % Make the output directory
copyfile([mfilename('fullpath'), '.m'], outputdir);  % Save the current script in the output directory

% The following lies generate a README.txt file under outputdir
readme = 'README.txt';
fid = fopen(fullfile(outputdir, readme), 'w');
if fid == -1
    error('Cannot open file %s.', readme);
end
fprintf(fid, 'This folder contains the intersection-form version of the Fortran source\n');
fprintf(fid, 'files. The files in this folder are generated by the %s.m script,\n', mfilename);
fprintf(fid, 'and they are NOT intended to be readable.\n');
fprintf(fid, '\n');
fprintf(fid, 'This project is coded in the free form, yet some platforms accept only\n');
fprintf(fid, 'fixed-form Fortran code, for example, the MATLAB MEX on Windows. The code\n');
fprintf(fid, 'in this folder can serve such a purpose.\n');
fprintf(fid, '\n');
fprintf(fid, 'In the intersection form, each continued line has an ampersand at column\n');
fprintf(fid, '73, and each continuation line has an ampersand at column 6. A Fortran file\n');
fprintf(fid, 'in such a form can be compiled both as fixed form and as free form.\n');
fprintf(fid, '\n');
fprintf(fid, 'See http://fortranwiki.org/fortran/show/Continuation+lines for details.\n');
fprintf(fid, '\n');
fprintf(fid, 'Zaikun Zhang (www.zhangzk.net), %s', date);
fclose(fid);

% The following lines perform the refactoring in the current directory
refactor_dir(inputdir, outputdir, ignorefiles);

% The following lines get a cell array containing the names (but not
% full path) of all the subdirectories of the given directory.
d = dir(inputdir);
isub = [d(:).isdir];
subdir = {d(isub).name};
subdir = setdiff(subdir, [{'.','..'}, ignoredir]);  % Exclude the ignored directories

% The following lines perform the refactoring in the subdirectories of
% the current directory.
for i = 1 : length(subdir)
    mkdir(fullfile(outputdir, subdir{i}));
    refactor_dir(fullfile(inputdir, subdir{i}), fullfile(outputdir, subdir{i}), ignorefiles);
end


function refactor_dir(inputdir, outputdir, ignorefiles)
%REFACTOR_DIR refactors the files in inputdir and save them in outputdir.

% Get the list of Fortran files in inputdir, copy them to outputdir, and
% refactor the f90 files.
ffiles = [dir(fullfile(inputdir, '*.f90')); dir(fullfile(inputdir, '*.F90')); dir(fullfile(inputdir, '*.f')); dir(fullfile(inputdir, '*.F'))];
ffiles = setdiff({ffiles.name}, ignorefiles);
for j = 1 : length(ffiles)
    copyfile(fullfile(inputdir, ffiles{j}), outputdir);
    [~, ~, ext] = fileparts(ffiles{j});
    if strcmpi(ext, '.f90')
        refactor_file(fullfile(outputdir, ffiles{j}));
    end
end
% Remove the backup files.
delete(fullfile(outputdir, '*.bak'));
delete(fullfile(outputdir, '*.f90'));
delete(fullfile(outputdir, '*.F90'));

% Copy the file list from inputdir to outputdir and revise it.
filelist = 'ffiles.txt'; % Name of the file list.
if exist(fullfile(inputdir, filelist), 'file')
    copyfile(fullfile(inputdir, filelist), outputdir);
    refactor_filelist(fullfile(outputdir, filelist));
end

% Copy the header files to the output directory.
hfiles = dir(fullfile(inputdir, '*.h'));
hfiles = {hfiles.name};
for j = 1 : length(hfiles)
    copyfile(fullfile(inputdir, hfiles{j}), outputdir);
end

% Copy the Makefile to the output directory.
mkfiles = [dir(fullfile(inputdir, 'makefile')); dir(fullfile(inputdir, 'Makefile'))];
mkfiles = setdiff({mkfiles.name}, ignorefiles);
for j = 1 : length(mkfiles)
    copyfile(fullfile(inputdir, mkfiles{j}), outputdir);
end


function refactor_file(filename)
%REFACTOR_FILE refactors a given Fortran file into the "intersection form".
% See http://fortranwiki.org/fortran/show/Continuation+lines for details.
% The new file has the same name as the original file, but the extension
% ".f90" will be changed to ".f", and ".F90" will be changed to ".F". If
% the new file has the same name as the original one, then the original
% file will be backuped in "ORIGINAL_FILE_NAME.bak".

fid = fopen(filename, 'r');
if fid == -1
    error('Cannot open file %s.', filename);
end

% Read the file into a cell of strings
data = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '');
fclose(fid);
cstr = data{1};
cstr = deblank(cstr);  % Remove trailing blanks

i = 1;
j = 1;
k = 1;

while(j <= length(cstr))
    strtmp = cstr{j};
    strtmp_trimed = strtrim(strtmp);

    if isempty(strtmp_trimed) || strcmp(strtmp_trimed(1), '!') || strcmp(strtmp_trimed(1), '#')
        strs{k} = strtmp_trimed;
        k = k + 1;
        i = j + 1;
        j = j + 1;
    elseif j < length(cstr) && ~isempty(strtmp) && strcmp(strtmp(end), '&')
        cstr{j} = strtmp(1 : end-1);
        strtmp = strtrim(cstr{j+1});
        if (~isempty(strtmp) && strcmp(strtmp(1), '&'))
            strtmp = strtmp(2 : end);
            cstr{j+1} = strtmp;
        end
        j = j + 1;
    else
        strs{k} = strjoin(cstr(i:j), ' ');
        strs{k} = refactor_str(strs{k}, 7, 72);
        k = k + 1;
        i = j + 1;
        j = j + 1;
    end
end

% Save the refactored file
refactored_filename = regexprep(filename, '.f90$', '.f');
refactored_filename = regexprep(refactored_filename, '.F90$', '.F');
if strcmp(refactored_filename, filename)
    copyfile(filename, [filename, '.bak']);
end
fid = fopen(refactored_filename, 'wt');
if fid == -1
    error('Cannot open file %s.', refactored_filename);
end

[~, fname, ext] = fileparts(filename);
fprintf(fid, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n');
fprintf(fid, '! This is the intersection-form version of %s.\n', [fname, ext]);
fprintf(fid, '! The file is generated automatically and is NOT intended to be readable.\n');
fprintf(fid, '!\n');
fprintf(fid, '! In the intersection form, each continued line has an ampersand at column\n');
fprintf(fid, '! 73, and each continuation line has an ampersand at column 6. A Fortran\n');
fprintf(fid, '! file in such a form can be compiled both as fixed form and as free form.\n');
fprintf(fid, '!\n');
fprintf(fid, '! See http://fortranwiki.org/fortran/show/Continuation+lines for details.\n');
fprintf(fid, '!\n');
fprintf(fid, '! Generated using the %s.m script by Zaikun Zhang (www.zhangzk.net)\n! on %s.\n', mfilename, date);
fprintf(fid, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n\n');

for i = 1 : length(strs)
    fprintf(fid, strs{i});
    if i < length(strs)
        fprintf(fid, '\n');
    end
end
fclose(fid);
evalc('system([''dos2unix -q '', refactored_filename])');  % Without this, sunf95 will complain. Supress the error message if dos2unix is unavailable.


function str = refactor_str(str, first, last)
%REFACTOR_STR refactors a given string into the "intersection form".
% See http://fortranwiki.org/fortran/show/Continuation+lines for details.

spaces = '                                                                ';  %%

str = regexprep(str, '\t', '    ');  % Replace each tab by four spaces

if sum(isspace(str)) == length(str)
    return;
end

first_non_space = min(find(~isspace(str), 1, 'first'));  % Index of the first non-space character in str
num_leading_spaces = first - 1 + first_non_space - 1;  % Number of leading spaces in str after refactoring

leading_spaces = spaces(1 : num_leading_spaces); % Save the leading spaces in a string

width_first_row = last - num_leading_spaces; % Width of the first row of str after refactoring
width = last - first + 1;  % Width of the other rows of str after refactoring

str = strtrim(str);  % Remove the leading and trailing spaces from str
first_non_digit = min(find(~isdigit(str), 1, 'first'));
leading_digits = str(1 : first_non_digit - 1);  % Leading digits in the string; they are statement labels
first_exclamation = length(str) + 1;
for ic = 1 : length(str)
    if double(str(ic)) == double('!') && mod(sum(double(str(1:ic)) == double('''')), 2) == 0 && mod(sum(double(str(1:ic)) == double('"')), 2) == 0
        first_exclamation = ic;
        break;
    end
end
comment = str(first_exclamation : end);
str = strtrim(str(first_non_digit : first_exclamation - 1));  % The string without the statement label and comment
str = regexprep(str,' +',' ');  % Replace all the continuous multiple spaces by one single space
len = length(str);  % Length of the trimmed str

row = ceil((len - width_first_row)/width) + 1;  % Number of rows of str after refactoring

strnew = [leading_spaces, str(1 : min(len, width_first_row))];  % The first row after refactoring

for i = 2 : row
    strnew = [strnew, '&'];  % Append an '&' at the end of the i-1 th row.
    strtmp = str(width_first_row + (i-2)*width + 1 : min(len, width_first_row + (i-1)*width));  % Content of the i-th row
    strtmp = [spaces(1:first-2), '&', strtmp];  % Add first - 2 spaces and an '&' at the beginning of the i-th row
    strtmp = ['\n', strtmp];  % Add a '\n' at the beginning of the i-th row
    strnew = [strnew, strtmp];
end

str = strnew;
str(1 : first_non_digit - 1) = leading_digits;  % Put the statement labels back
if ~isempty(comment)
    str = [str, '\n', leading_spaces, comment];  % Put the comment back
end

function isd = isdigit(c)
isd = ischar(c) & (double(c) >= double('0')) & (double(c) <= double('9'));

function refactor_filelist(filename)

fid = fopen(filename, 'r');
if fid == -1
    error('Cannot open file %s.', filename);
end

% Read the file into a cell of strings
data = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '');
fclose(fid);
cstr = data{1};
cstr = deblank(cstr);  % Remove trailing blanks

for i = 1 : length(cstr)
    cstr{i} = regexprep(cstr{i}, '.F90$', '.F');
    cstr{i} = regexprep(cstr{i}, '.f90$', '.f');
end

% Save the file again
fid = fopen(filename, 'w');
if fid == -1
    error('Cannot open file %s.', filename);
end
fprintf(fid, '%s\n', cstr{:});
fclose(fid);
