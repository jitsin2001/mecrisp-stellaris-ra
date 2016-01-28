\ util.fth
: cnt0   ( m -- b )                      \ count trailing zeros with hw support
   dup negate and 1-
   clz negate #32 + 1-foldable ;
: bits@  ( m adr -- b )                  \ get bitfield at masked position e.g $1234 v ! $f0 v bits@ $3 = . (-1)
   @ over and swap cnt0 rshift ;
: bits!  ( n m adr -- )                  \ set bitfield value n to value at masked position
   >R dup >R cnt0 lshift                 \ shift value to proper position
   R@ and                                \ mask out unrelated bits
   R> not R@ @ and                       \ invert bitmask and maskout new bits in current value
   or r> ! ;                             \ apply value and store back
                                         \ example :
                                         \   RCC_PLLCFGR.PLLN = 400 -> #400 $1FF #6 lshift RCC_PLLCFGR bits!
                                         \ PLLN: bit[14:6] -> mask :$1FF << 6 = $7FC0
                                         \ #400 $7FC0 RCC_PLLCFGR bits!
                                         \ $1FF #6 lshift constant PLLN
                                         \ #400 PLLN RCC_PLLCFGR bits!
: u.8 ( n -- )                           \ unsigned output 8 digits
   0 <# # # # # # # # # #> type ;
: x.8 ( n -- )                           \ hex output 8 digits
   base @ hex swap u.8 base ! ;
: x.2 ( n -- )                           \ hex output 2 digits
   base @ hex swap 0 <# # # #> type base ! ;
: cfill ( c n a -- )                     \ fill memory block at address a length n with char c
   tuck + swap do dup i c! loop drop ;
: d2**  ( n -- d )                       \ return 2^n 
   dup #31 > if
     #32 - 1 swap lshift 0 swap
   else
     1 swap lshift 0
   then 1-foldable ;
: dxor ( d d -- d )                      \ double xor
   rot xor -rot xor swap 4-foldable ;
: $. ( -- )                              \ print a dollar sign 
   [char] $ emit ;
