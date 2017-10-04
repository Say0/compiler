.section	".rodata"
.align	8
.section	".text"
fib.10:
	cmp	%i2, 1
	bg	ble_else.24
	nop
	retl
	nop
ble_else.24:
	sub	%i2, 1, %i3
	st	%i2, [%i0 + 0]
	mov	%i3, %i2
	st	%o7, [%i0 + 4]
	call	fib.10
	add	%i0, 8, %i0	! delay slot
	sub	%i0, 8, %i0
	ld	[%i0 + 4], %o7
	ld	[%i0 + 0], %i3
	sub	%i3, 2, %i3
	st	%i2, [%i0 + 4]
	mov	%i3, %i2
	st	%o7, [%i0 + 12]
	call	fib.10
	add	%i0, 16, %i0	! delay slot
	sub	%i0, 16, %i0
	ld	[%i0 + 12], %o7
	ld	[%i0 + 4], %i3
	add	%i3, %i2, %i2
	retl
	nop
.global	min_caml_start
min_caml_start:
	save	%sp, -112, %sp
	set	30, %i2
	st	%o7, [%i0 + 4]
	call	fib.10
	add	%i0, 8, %i0	! delay slot
	sub	%i0, 8, %i0
	ld	[%i0 + 4], %o7
	st	%o7, [%i0 + 4]
	call	min_caml_print_int
	add	%i0, 8, %i0	! delay slot
	sub	%i0, 8, %i0
	ld	[%i0 + 4], %o7
	ret
	restore
