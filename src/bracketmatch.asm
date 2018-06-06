.data
.globl FindMatchingClosingBracket
.globl FindMatchingOpeningBracket

.text
j end
# FindMatchingClosingBracket
# Cerca in una stringa la parentesi chiusa corrispondente
# ad una aperta passata come parametro
# INPUT
# a0: Indirizzo della stringa in cui cercare
# a1: Lunghezza della stringa
# a2: Posizione della parentesi da cui cercare
# OUTPUT
# v0: Posizione della parentesi trovata
# v1: 0 se e' stata trovata, 1 se non e' stata trovata

FindMatchingClosingBracket:
	sub $sp, $sp, 12
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)

	move $s0, $a0	# Indirizzo codice
	move $s1, $a1	# Lunghezza codice
	move $s2, $a2	# PC start
	
	li $t0, 0		# bracket
	li $v1, 0		# Resettiamo il registro usato per l'errore
	
FMCB_Do:
	# Estrae il carattere
	add $t2, $s0, $s2
	lb $t1, 0($t2)
	
	li $t3, '['
	beq $t1, $t3, FMCB_AddBracket
	li $t3, ']'
	beq $t1, $t3, FMCB_SubBracket
	
	j FMCB_Condition

FMCB_AddBracket:
	addi $t0, $t0, 1
	j FMCB_Condition

FMCB_SubBracket:
	subi $t0, $t0, 1
	j FMCB_Condition

FMCB_Condition:
	
	addi $s2, $s2, 1				# Incrementa l'index
	
	sub $t4, $s2, $s1			# index < codeLen
	bgez $t4, FMCB_HandleError		# !(i < 12) --> Non c'e' la parentesi. syntax error
	
	bne $t0, $zero, FMCB_Do	# bracket != 0
	li $t4, ']'
	bne $t1, $t4, FMCB_Do	# char != ']'
	
FMCB_Exit:
	move $v0, $s2
	subi $v0, $v0, 1		# Perchè altrimenti restituisce il carattere dopo la parentesi
	
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	addi $sp, $sp, 12
	jr $ra

FMCB_HandleError:
	li $v1, 1	# Se non troviamo la parentesi corrispondente
	j FMCB_Exit	# Allora mettiamo anche $v1 a 1
	

# FindMatchingOpeningBracket
# Cerca in una stringa la parentesi aperta corrispondente
# ad una chiusa passata come parametro
# INPUT
# a0: Indirizzo della stringa in cui cercare
# a1: Posizione della parentesi da cui cercare
# OUTPUT
# v0: Posizione della parentesi
# v1: 0 se e' stata trovata, 1 se non e' stata trovata
FindMatchingOpeningBracket:
	sub $sp, $sp, 8
	sw $s0, 0($sp)
	sw $s1, 4($sp)

	move $s0, $a0	# Indirizzo codice
	move $s1, $a1	# PC start
	
	li $t0, 0		# bracket
	li $v1, 0		# registro usato per errori
FMOB_Do:
	# Estrae il carattere
	add $t2, $s0, $s1
	lb $t1, 0($t2)
	
	li $t3, ']'
	beq $t1, $t3, FMOB_AddBracket
	li $t3, '['
	beq $t1, $t3, FMOB_SubBracket
	
	j FMOB_Condition

FMOB_AddBracket:
	addi $t0, $t0, 1
	j FMOB_Condition

FMOB_SubBracket:
	subi $t0, $t0, 1
	j FMOB_Condition

FMOB_Condition:
	
	subi $s1, $s1, 1		# Decrementa l'index
	
	bltz $s1, FMOB_HandleError	# index < 0 --> Parentesi non esiste
	
	bne $t0, $zero, FMOB_Do		# bracket != 0
	li $t4, '['
	bne $t1, $t4, FMOB_Do		# char != ']'
	
FMOB_Exit:
	move $v0, $s1
	addi $v0, $v0, 1		# Perche' altrimenti restituisce il carattere dopo la parentesi
	
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	jr $ra

FMOB_HandleError:
	li $v1, 1	# Se non troviamo la parentesi corrispondente
	j FMOB_Exit	# Allora mettiamo anche $v1 a 1

end: