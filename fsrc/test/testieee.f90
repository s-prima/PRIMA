program testieee
    use ieee_arithmetic, only : my_nan => ieee_is_nan
    implicit none
    print *, my_nan(0.0)
end program testieee
