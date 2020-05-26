#Project #1
#Caitlin McEleney

.data
			.align 2
	arg1:		.word 0
	arg2: 		.word 0
	arg1Parsed:	.space 40
	error: 		.asciiz "Incorrect argument provided."
	sm: 		.asciiz "\nSigned Magnitude: "
	one:		.asciiz "\nOne's Complement: "
	gray: 		.asciiz "\nGray Code: "
	dbl: 		.asciiz "\nDouble Dabble: "
	msg1: 		.asciiz "You entered "
	msg2: 		.asciiz " which parsed to "
	msg3: 		.asciiz "\nIn hex it looks like "
	space:		.asciiz " "
	negSign:		.asciiz "-"	#negative flag for dd
#macro to get command line arguments
.macro load_args
	lw $t0, 0($a1)
	sw $t0, arg1
	lw $t0, 4($a1)
	sw $t0, arg2
.end_macro
#macro to print messages
.macro printString ($arg1)
	li $v0,4
	la $a0,$arg1
	syscall
.end_macro

.macro printArg($arg1)
	lw $a0, $arg1
	li $v0, 4
	syscall
.end_macro

.macro printInt($arg1)
	li $v0, 1
	lw $a0, $arg1
	syscall
.end_macro

.macro toHex($arg1)
	lw $t0, $arg1
	li $v0, 34
	add $a0, $t0, $zero
	syscall
.end_macro

.text
.globl main
main:
	load_args()
	lw $t0, arg1		#set base address to $t0
	li $t1, 0		#sets the int to 0
	lb $s0, ($t0)		#loads base byte of arg1 from $t0 to $s0
	li $s2, 0		#sets $s2 to 0 to change of negative check
	lw $t3, arg2		#loads arg2 into $t3
	lb $s1, ($t3)
	beq $s0, '-', negative	#if negative number
	beq $s1, '1' ,loop	#if equal and positive with valid arg2, goes to parsing loop
	beq $s1, 's', loop	
	beq $s1, 'g', loop
	beq $s1, 'd', loop
	printString(error)	#prints error message
	j exit
negative: 
	addi $t0, $t0, 1	#increment address to start past '-'
	lb $s0, ($t0)		#changes the starting $s0 to the next char
	li $s2, 1		#to give indicator that the int was negative
	beq $s1, '1' ,loop	#if equal and positive with valid arg2 for negative numbers, goes to parsing loop
	beq $s1, 's', loop	
	beq $s1, 'g', loop
	beq $s1, 'd', loop
	printString(error)
	j exit			#if not caught for any valid arg 2, prints error, goes to exit
loop:
	blt $s0, '0', printParsed	
	bgt $s0, '9', printParsed	#branches if digit is no longer between 0-9
	sub $t2, $s0, '0'		#subtracts the character by '0'
	mul $t1, $t1, 10		#multiplies the int by 10 to increment place saved back into $t1
	add $t1, $t1, $t2		#adds the incremented sum by the char
	addi $t0, $t0, 1		#adds byte to $s0 to increment
	lb $s0, ($t0)			#sets $s0 to next
	j loop
printParsed:			
	bgt $s2, $0, negativePrintParse	#check if it was flagged as negative, sends to negative parse
	sw $t1, arg1Parsed		#saves the value of parsed to variable
	printString(msg1)
	printArg(arg1)
	printString(msg2)
	printInt(arg1Parsed)
	printString(msg3)
	toHex(arg1Parsed)
	beq $s1, '1' ,onesPos	#after translating to hex, each directs it to its own number translation
	beq $s1, 's', signedPos	#signed	
	beq $s1, 'g', grayCode	#gray
	beq $s1, 'd', ddPos
	j exit
negativePrintParse:
	sub $t1, $0, $t1		#negates 
	sw $t1, arg1Parsed		#saves value of parsed to variable
	printString(msg1)
	printArg(arg1)
	printString(msg2)
	printInt(arg1Parsed)
	printString(msg3)
	toHex(arg1Parsed)
	beq $s1, '1' ,onesNeg	#after translating to hex, each directs it to its own number translation
	beq $s1, 's', signedNeg	#signed	
	beq $s1, 'g', grayCode	#gray
	beq $s1, 'd', ddNeg
	j exit
onesNeg:			#two -> ones : subtract one
	lw $t1, arg1Parsed	#loads the neg argument
	subi $t1, $t1, 1	#subtracts one
	sw $t1, arg1Parsed	#stores the new num in arg1Parsed
	printString(one)
	toHex(arg1Parsed)
	j exit
onesPos:			#no change needed
	printString(one)
	toHex(arg1Parsed)
	j exit
signedPos:			#no change needed
	printString(sm)
	toHex(arg1Parsed)
	j exit
signedNeg:
	lw $t0, arg1Parsed	#loads arg1Parsed into $t0
	sub $t0, $zero, $t0	#0- (-arg1Parsed) -> positive
	lui $t1, 0x8000		#sets the first digit to binary 1
	add $t0, $t0, $t1	#adds the binary 1 to the rest of the hex
	sw $t0, arg1Parsed	
	printString(sm)
	toHex(arg1Parsed)
	j exit
grayCode:
	lw $t0, arg1Parsed	#loads arg1Parsed into $t0
	li $t1, 0		
	srl $t1, $t0, 1		#num >> 1 into $t1
	xor $t0, $t1, $t0	#num ^ (num >> 1) $t0 ^ $t1	
	sw $t0, arg1Parsed	
	printString(gray)
	toHex(arg1Parsed)
	j exit
ddPos:
	lw $s0, arg1Parsed	#loads arg1Parsed into $t0	(var v)
	li $s1, 0		#making sure $s1 is zeroed out	(var r)
	li $s2, 0		#zeroed out $t2			(var k)
	li $t8, 0		#set mv to zero	
	ddloop1:			#outer loop for value = 0
		beq $s2, 32, printDD	#if k is equal to 32, break to print
		addi $s2, $s2, 1	#increment k by 1
		li $t3, 0		#var msb = 0 (false)
		slti $t3, $s0, 0	 #if v< 0, msb is 1
		sll $s0, $s0, 1		#v = v << 1
		sll $s1, $s1, 1 	#r = r << 1 
		ble $t3, 0, skipmsb	#if msb <= 0, skips next line
		addi $s1, $s1, 1	#if msb was set as 1, add one to r
		j skipmsb
	skipmsb:			#if not flagged as <0, skip to here
					#if k < 31 && r != 0:
		bge $s2, 32, ddloop1	#if k >= 32 skip ddloop1, if flagged
		beq $s1, $zero, ddloop1	#if r = 0 go back to outer
		li $t7, 0		#sets/resets i to 0
		li $s4, 0xf0000000	#$t4 = mask	
		li $s5, 0x40000000	#$t5 = cmp
		li $s6, 0x30000000	#$t6 = add
		j ddloop2
		ddloop2:
			bge $t7, 8, ddloop1	#if i >= 8, breaks to the outerloop
			addi $t7 ,$t7, 1	#increment i by 1 (++i)
			and $t8, $s4, $s1	#mv = mask & r 		
			bge $s5, $t8, cont2 	#if cmp >= mv, skip next line
			addu $s1, $s1, $s6	#r = r + add
			j cont2
		cont2:		
			srl $s4, $s4, 4		#mask srl by 4
			srl $s5, $s5, 4		#cmp srl by 4
			srl $s6, $s6, 4		#add srl by 4
			j ddloop2
	printDD:
		sw $s1, arg1Parsed
		printString(dbl)
		toHex(arg1Parsed)
		j exit

ddNeg:
	lw $s0, arg1Parsed	#loads arg1Parsed into $t0	(var v)
	li $s1, 0		#making sure $s1 is zeroed out	(var r)
	li $s2, 0		#zeroed out $t2			(var k)
	li $t8, 0		#set mv to zero	
	sub $s0, $zero, $s0	#0- (-arg1Parsed) -> positive
	ddnloop1:			#outer loop for value = 0
		beq $s2, 32, printDDNeg	#if k is equal to 32, break to print
		addi $s2, $s2, 1	#increment k by 1
		li $t3, 0		#var msb = 0 (false)
		slti $t3, $s0, 0	 #if v< 0, msb is 1
		sll $s0, $s0, 1		#v = v << 1
		sll $s1, $s1, 1 	#r = r << 1 
		ble $t3, 0, skipmsbn	#if msb <= 0, skips next line
		addi $s1, $s1, 1	#if msb was set as 1, add one to r
		j skipmsbn
	skipmsbn:			#if not flagged as <0, skip to here
		bge $s2, 32, ddnloop1	#if k >= 32 skip ddloop1, if flagged
		beq $s1, $zero, ddnloop1	#if r = 0 go back to outer
		li $t7, 0		#sets/resets i to 0
		li $s4, 0xf0000000	#$t4 = mask	
		li $s5, 0x40000000	#$t5 = cmp
		li $s6, 0x30000000	#$t6 = add
		j ddnloop2
		ddnloop2:
			bge $t7, 8, ddnloop1	#if i >= 8, breaks to the outerloop
			addi $t7 ,$t7, 1	#increment i by 1 (++i)
			and $t8, $s4, $s1	#mv = mask & r 		
			bge $s5, $t8, cont2n 	#if cmp >= mv, skip next line
			addu $s1, $s1, $s6	#r = r + add
			j cont2n
		cont2n:		
			srl $s4, $s4, 4		#mask srl by 4
			srl $s5, $s5, 4		#cmp srl by 4
			srl $s6, $s6, 4		#add srl by 4
			j ddnloop2
	printDDNeg:
		sw $s1, arg1Parsed
		printString(dbl)
		printString(negSign)
		toHex(arg1Parsed)
		j exit
exit:	li $v0, 10
	syscall	
