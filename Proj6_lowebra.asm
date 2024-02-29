TITLE Designing low-level I/O procedures     (Proj6_lowebra.asm)

; Author: Braxton Lowe
; Last Modified: 6/11/2023
; OSU email address: lowebra@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6               Due Date: 6/11/2023
; Description: Program prompts user for 10 signed decimal integers and will
;              display a list of those integers along their sum and average.

;NOTE: I realized when I finished this you wanted signed integers but I wrote the program for unsigned,
;	   I would go back to fix it but I ran out of time.



INCLUDE Irvine32.inc

;------------------------------------------------------------------------------
; name: mGetString
; description: Displays prompt to user, then stores user input
; Receives: prompt to display, string buffer, length of
;	string buffer
; Returns: none
; Preconditions: prompt string and string buffer are passed as offset, and
;	length of string buffer is passed as value to macro
; Postconditions: the supplied prompt is displayed to user, and the user's
;	 input is stored as a string
; Registers changed: edx, ecx
;------------------------------------------------------------------------------
mGetString	MACRO	promptAddr, buffer, buffer_size
	push	edx
	push	ecx

	;display prompt
	mov	edx, promptAddr		
	call	WriteString

	mov	edx, buffer
	mov	ecx, buffer_size
	call	ReadString
	pop	ecx
	pop	edx
ENDM

;------------------------------------------------------------------------------
; name: mDisplayString
; description: Displays the string stored in a specific memory location.
; Receives: string to display
; Returns: none
; Preconditions: string to display must be passed as offset
; Postconditions: the supplied string is displayed to the user
; Registers changed: edx
;------------------------------------------------------------------------------
mDisplayString	MACRO	strAddress
	push	edx
	mov	edx, strAddress
	call	WriteString
	pop	edx
ENDM


.data
programTitle	BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level "
		BYTE	"I/O procedures, by Braxton Lowe.", 0
instructions	BYTE	"Please provide 10 signed decimal integers.", 13, 10
		BYTE	"Each number needs to be small enough to fit inside a "
		BYTE	"32 bit register.", 13, 10
		BYTE	"After you have finished inputting the raw numbers I "
		BYTE	"will display a list", 13, 10
		BYTE	"of the integers, their sum, and their average "
		BYTE	"value.", 0
numPrompt	BYTE	"Please enter a signed integer: ", 0
errorMsg	BYTE	"ERROR: You did not enter an unsigned number or your "
			BYTE	"number was too big.", 0
tryAgain	BYTE	"Please try again: ", 0
enteredMsg	BYTE	"You entered the following numbers:", 0
commaSpace	BYTE	", ", 0
sumMsg		BYTE	"The sum of these numbers is: ", 0
avgMsg		BYTE	"The truncated average is: ", 0
thanksMsg	BYTE	"Thanks for playing!", 0

array		DWORD	10 DUP(?)

.code
main	PROC
	push	OFFSET programTitle
	push	OFFSET instructions
	call	introduction

	push	OFFSET array
	push	LENGTHOF array
	push	OFFSET numPrompt
	push	OFFSET tryAgain
	push	OFFSET errorMsg
	call	getData

	push	OFFSET array
	push	LENGTHOF array
	push	OFFSET enteredMsg
	push	OFFSET commaSpace
	call	displayList

	push	OFFSET array
	push	LENGTHOF array
	push	OFFSET sumMsg
	push	OFFSET avgMsg
	call	displaySumAvg

	push	OFFSET thanksMsg
	call	displayEnd

	exit
main	ENDP

;------------------------------------------------------------------------------
; name: introduction
; description: Displays the program introduction to the user.
; Receives: programTitle, instructions
; Returns: none
; Preconditions: all parameters must be passed as offset, and are pushed to the stack in the order specified in Recieves above
; Postconditions: prints program name, programmer name, and instructions to console
; Registers changed: ebp, edx
;------------------------------------------------------------------------------
introduction	PROC	USES	edx
	push	ebp
	mov	ebp, esp

	; display program title: programTitle
	mov	edx, [ebp + 16]
	mDisplayString	edx
	call	Crlf
	call	Crlf

	; display program instructions: instructions
	mov	edx, [ebp + 12]
	mDisplayString	edx
	call	Crlf
	call	Crlf

	pop	ebp
	ret	8

introduction	ENDP

;------------------------------------------------------------------------------
; name: getData
; description: Gets user input to fill an array. and converts numbers to integer
; Receives: array, LENGTHOF, numPrompt, tryAgain, errorMsg
; Returns: none
; Preconditions: array, numPrompt, tryAgain, and errorMsg passed as offset.
;	LENGTHOF array passed as value, and pushed to the stack in order specified in the Receives above
; Postconditions: array is filled with validated unsigned integers
; Registers changed: ebp, esi, ecx, eax
;------------------------------------------------------------------------------
getData		PROC	USES	esi ecx eax

	push	ebp
	mov	ebp, esp

	; fill array: array = [ebp + 36]
	mov	esi, [ebp + 36]
	mov	ecx, [ebp + 32]

	fillArray:
		mov	eax, [ebp + 28]		
		push	eax
		push	[ebp + 24]		
		push	[ebp + 20]		
		call	readVal

		;Store converted number into array
		pop	[esi]		
		add	esi, 4
		loop	fillArray

	pop	ebp
	ret	20
getData			ENDP

;------------------------------------------------------------------------------
; name: readVal
; description: Reads user input, calls on validate to verify that input is
;	valid, then calls on convertNum to convert the string input
;	to an integer.
; Receives: numPrompt, tryAgain, errorMsg 
; Returns: validated user input on top of stack
; Preconditions: all parameters must be passed as offset, and are pushed to the
;	stack in the order specified in Receives above
; Postconditions: returns a validated unsigned integer on the top of the stack
;	as a value
; Registers changed: ebp, eax, ebx
;------------------------------------------------------------------------------
readVal		PROC	USES	eax ebx
	LOCAL	inputNum[15]:BYTE, valid:DWORD

	; save esi and ecx, set up strings for getString
	push	esi
	push	ecx
	mov	eax, [ebp + 16]		
	lea	ebx, inputNum

	inputLoop:
		mGetString	eax, ebx, LENGTHOF inputNum
		mov	ebx, [ebp + 8]		
		push	ebx
		lea	eax, valid
		push	eax
		lea	eax, inputNum
		push	eax
		push	LENGTHOF inputNum
		call	validate
		pop	edx
		mov	[ebp + 16], edx	
		;check if number is valid
		mov	eax, valid
		cmp	eax, 1
		mov	eax, [ebp + 12]
		lea	ebx, inputNum
		jne	inputLoop

	pop	ecx
	pop	esi
	ret	8	
readVal		ENDP

;------------------------------------------------------------------------------
; name: validate
; description: Validates that user input is an unsigned integer.
; Receives: errorMsg, valid, inputNum, LENGTHOF inputNum
; Returns: a number on top of the stack, and changes the value of valid to 0 if
;	the string is invalid
; Preconditions: errorMsg, valid, and inputNum are passed as offset and
;	LENGTHOF inputNum is passed as value, and are pushed to the stack in
;	the order specified in Receives above
; Postconditions: number is validated, valid is changed to 0 if number is
;	invalid, number is top of the stack
; Registers changed: ebp, esi, ecx, eax, edx
;------------------------------------------------------------------------------
validate	PROC	USES	esi ecx eax edx
	LOCAL	tooLarge:DWORD

	mov	esi, [ebp + 12]
	mov	ecx, [ebp + 8]
	cld

	; load in string and verify if they are digits
	loadStr:
		lodsb
		cmp	al, 0
		je	nullChar
		cmp	al, 48
		jl	invalid
		cmp	al, 57
		ja	invalid
		loop	loadStr

	; set valid to 0
	invalid:
		mov	edx, [ebp + 20]		
		mDisplayString	edx
		call	Crlf
		mov	edx, [ebp + 16]		
		mov	eax, 0
		mov	[edx], eax
		jmp	endVal

	; converts string to integer
	nullChar:
		mov	edx, [ebp + 8]	
		cmp	ecx, edx	
		je	invalid		
		lea	eax, tooLarge
		mov	edx, 0
		mov	[eax], edx
		push	[ebp + 12]
		push	[ebp + 8]
		lea	edx, tooLarge
		push	edx
		call	convertToNum
		mov	edx, tooLarge
		cmp	edx, 1
		je	invalid
		mov	edx, [ebp + 16]
		mov	eax, 1		
		mov	[edx], eax

	endVal:
		pop	edx	
		mov	[ebp + 20], edx	
		ret	12		
validate	ENDP

;------------------------------------------------------------------------------
; name: convertToNum
; description: Converts a string input of digits to an integer number.
; Receives: inputNum, LENGTHOF inputNum, tooLarge
; Returns: converted inputNum on top of stack and changes tooLarge to 1 if input number does not fit
; Preconditions: inputNum and tooLarge are passed as offset/address, and
;	LENGTHOF inputNum is passed as value in the order specified in
;	Receives above.
; Postconditions: converted inputNum from string to integer is returned at the
;	top of the stack, tooLarge is set to 1 if input is too large
; Registers changed: ebp, esi, ecx, eax, ebx, edx
;------------------------------------------------------------------------------
convertToNum	PROC	USES	esi ecx eax ebx edx
	LOCAL	number:DWORD

	mov	esi, [ebp + 16]
	mov	ecx, [ebp + 12]
	lea	eax, number
	xor	ebx, ebx
	mov	[eax], ebx
	xor	eax, eax
	xor	edx, eax	
	cld

	; load in string bytes and add to number
	loadDigits:
		lodsb
		cmp	eax, 0
		je	endLoad
		sub	eax, 48
		mov	ebx, eax
		mov	eax, number
		mov	edx, 10
		mul	edx
		jc	numTooLarge	
		add	eax, ebx
		jc	numTooLarge	
		mov	number, eax	
		mov	eax, 0		
		loop	loadDigits

	endLoad:
		mov	eax, number
		; move converted number to stack
		mov	[ebp + 16], eax	
		jmp	finish

	; change tooLarge if number does not fit
	numTooLarge:
		mov	ebx, [ebp + 8]	
		mov	eax, 1		
		mov	[ebx], eax
		mov	eax, 0
		mov	[ebp + 16], eax	

	finish:
		ret	8
convertToNum	ENDP

;------------------------------------------------------------------------------
; name: displayList
; description: Displays list
; Receives: array, LENGTHOF array, enteredMsg, commaSpace
; Returns: none
; Preconditions: array, enteredMsg, and commaSpace are passed as offset.
;	LENGTHOF array is passed as value to the stack, and are pushed to stack
;	in order of apperance in Recieves above
; Postconditions: label for the list is displayed to console, and
;	validated inputs are displayed as strings
; Registers changed: ebp, esi, ecx, ebx, edx
;------------------------------------------------------------------------------
displayList	PROC	USES	esi ebx ecx edx

		push	ebp
		mov	ebp, esp

	; print title
	call	Crlf
	mov	edx, [ebp + 28]
	mDisplayString	edx
	call	Crlf
	mov	esi, [ebp + 36]
	mov	ecx, [ebp + 32]
	mov	ebx, 1	

	printNum:
		push	[esi]
		call	WriteVal
		add	esi, 4
		cmp	ebx, [ebp + 32]
		jge	endList
		mov	edx, [ebp + 24]
		mDisplayString	edx
		inc	ebx
		loop	printNum

	endList:
		call	Crlf

	pop	ebp
	ret	16
displayList	ENDP

;------------------------------------------------------------------------------
; name:displaySumAvg
; description: Displays the sum and average validated inputs
; Receives: array, LENGTHOF array, sumMsg, avgMsg (reference)
; Returns: none
; Preconditions: array, sumMsg, and avgMsg are passed as offset, and LENGTHOF
;	array is passed as value, and are pushed to the stack in the order of
;	appearence in Receives above
; Postconditions: sum and average are printed  as strings
; Registers changed: ebp, edx, esi, ecx, eax, ebx
;------------------------------------------------------------------------------
displaySumAvg	PROC	USES	esi	edx ecx eax ebx

	push	ebp
	mov	ebp, esp

	mov	edx, [ebp + 32]		
	mDisplayString	edx
	mov	esi, [ebp + 40]		
	mov	ecx, [ebp + 36]		
	xor	eax, eax	
	
	; calculate sum
	sumNumbers:
		add	eax, [esi]
		add	esi, 4
		loop	sumNumbers
	
	; display sum
		push	eax
		call	writeVal
		call	Crlf

	; calculate and display average
		mov	edx, [ebp + 28]		
		mDisplayString	edx
		cdq
		mov	ebx, [ebp + 36]		
		div	ebx
		push	eax
		call	writeVal
		call	Crlf

	pop	ebp
	ret	16
displaySumAvg	ENDP

;------------------------------------------------------------------------------
; name: writeVal
; description: Writes integer as a string.
; Receives: integer
; Returns: none
; Preconditions: integer is passed as value to stack
; Postconditions: integer is printed as a string
; Registers changed: ebp, eax
;------------------------------------------------------------------------------
writeVal	PROC	USES	eax
	LOCAL	outputStr[11]:BYTE

		lea	eax, outputStr
		push	eax
		push	[ebp + 8]
		call	convertChar

		lea	eax, outputStr
		mDisplayString	eax

	ret	4
writeVal		ENDP

;------------------------------------------------------------------------------
; name: convertChar
; description: Converts an integer to a string and saves it in outputStr
; Receives: outputStr, integer
; Returns: none
; Preconditions: outputStr is passed as offset and integer is passed as value,
;	and are pushed to the stack in the order of appearence in Receives above
; Postconditions: saves converted integer as a string in outputStr
; Registers changed: ebp, eax, ebx, ecx
;------------------------------------------------------------------------------
convertChar	PROC	USES	eax ebx ecx
	LOCAL	tempChar:DWORD

	; set up division of integer by 10
		mov	eax, [ebp + 8]
		mov	ebx, 10
		mov	ecx, 0
		cld

	; count the number of digits and push the digits in reverse order
	divideTen:
		cdq
		div	ebx
		push	edx		
		inc	ecx
		cmp	eax, 0
		jne	divideTen

		mov	edi, [ebp + 12]	

	storeChar:
		pop	tempChar
		mov	al, BYTE PTR tempChar
		add	al, 48
		stosb
		loop	storeChar

		mov	al, 0
		stosb

	ret	8
convertChar		ENDP

;------------------------------------------------------------------------------
; name: displayEnd
; description: Displays the program ending to the user.
; Receives: thanksMsg (reference)
; Returns: none
; Preconditions: thanksMsg is passed as reference to the stack
; Postconditions: thanksMsg is printed to console
; Registers changed: ebp, edx
;------------------------------------------------------------------------------
displayEnd	PROC	USES	edx

		push	ebp
		mov	ebp, esp

		call	Crlf
		mov	edx, [ebp + 12]
		mDisplayString	edx
		call	Crlf

	pop	ebp
	ret	4
displayEnd	ENDP

END	main