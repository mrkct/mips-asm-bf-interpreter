.data
	.eqv pc $s0
	.eqv cursor $s1
	.eqv codeLength $s2
	.eqv fileDescriptor $s3
	.eqv isCommentFlag $s4
	.eqv startTime $s5
	.eqv returnCode $s6

	filename: .space 256
	msg_chooseFile: .asciiz "Seleziona il file da aprire: "
	msg_endExec: .asciiz "\n--- Programma terminato ---\n"
	msg_returnCode: .asciiz "Return code: "
	msg_runTime: .asciiz "Tempo di esecuzione: "

	errorMsg_fileTooBig: .asciiz "Il file e' troppo grande per essere eseguito.\n"
	errorMsg_noFileSelected: .asciiz "Nessun file e' stato selezionato.\n"
	errorMsg_cantOpenFile: .asciiz "Impossibile aprire il file. Nota: Su Linux i file vengono cercati in \home\user e non nella cartella del file sorgente\n"
	errorMsg_missingBracket: .asciiz "Impossibile trovare la parentesi corrispondente a quella in posizione "
	
	.eqv maxCodeSpace 8192
	codeSpace: .space maxCodeSpace		# Spazio per caricare il codice in memoria

	.eqv maxDataSpace 4096
	dataSpace: .space maxDataSpace
.text

main:
	# Dialog per file
	li $v0, 54
	la $a0, msg_chooseFile
	la $a1, filename
	li $a2, 256
	syscall
	
	# Se non e' stato inserito niente oppure se e' stato premuto cancella $a1 != 0
	bnez $a1, error_nofileselected
	
	# Il dialog aggiunge anche il \n alla fine del filename, 
	# che se passato alla syscall open file non fa trovare il file
	# bisogna toglierlo quindi. Questo pezzo di codice sostituisce i \n con \0. 
	# Tanto i \n non sono validi nei filename
	la $t0, filename
	li $t1, '\n'

	FilterNewline:
		lb $t2, 0($t0)
		bne $t2, $t1, FilterNewlineContinue
		li $t1, '\0'
		sb $t1, 0($t0)
		j FilterNewlineEnd

	FilterNewlineContinue:
		addi $t0, $t0, 1
		j FilterNewline

	FilterNewlineEnd:

	la $t0, filename
	
	# Apre il file con il codice bf, se non riesce salta all'handler dell errore
	li $v0, 13
	move $a0, $t0
	li $a1, 0
	li $a2, 0
	syscall
	move fileDescriptor, $v0

	bltz fileDescriptor, error_cantopenfile
	
	# Carichiamo il file in memoria e settiamo i registri utili ai valori iniziali
	li $v0, 14
	move $a0, fileDescriptor
	la $a1, codeSpace
	li $a2, maxCodeSpace
	syscall

	move codeLength, $v0
	
	li pc, 0
	
	li $v0, 30		# Salviamo il tempo di inizio, stile timestamp in ms.
	syscall			# Salviamo solo i bit inferiori
	move startTime, $a0	# Pero' cosi' possiamo contare al massimo fino ad 1 ora 1/2 circa
	
	ExecuteInstruction:
		la $t1, codeSpace
		add $t1, $t1, pc
		lb $t0, 0($t1)
		
		# Controlliamo se e' finita una riga allora disabilitiamo il flag commento
		li $t1, '\n'
		beq $t1, $t0, bf_ext_disablecomment
		
		# Controlliamo che non sia un commento questa riga. Se lo e' skippiamo
		bne $zero, isCommentFlag, ExecuteEnd
		
		li $t1, '+'
		beq $t1, $t0, bf_add
		li $t1, '-'
		beq $t1, $t0, bf_sub
		li $t1, '<'
		beq $t1, $t0, bf_mvleft
		li $t1, '>'
		beq $t1, $t0, bf_mvright
		li $t1, '.'
		beq $t1, $t0, bf_out
		li $t1, ','
		beq $t1, $t0, bf_in
		li $t1, '['
		beq $t1, $t0, bf_jforw
		li $t1, ']'
		beq $t1, $t0, bf_jback
		# Istruzioni estese. Queste NON fanno parte della versione originale Brainfuck
		li $t1, '@'
		beq $t1, $t0, bf_ext_quit
		li $t1, '$'
		beq $t1, $t0, bf_ext_printint
		li $t1, '?'
		beq $t1, $t0, bf_ext_intinput
		li $t1, '#'
		beq $t1, $t0, bf_ext_enablecomment

	ExecuteEnd:
		addi pc, pc, 1

		beq pc, codeLength, end
		j ExecuteInstruction

	# Messaggi di errore
	error_filetoobig:
		li $v0, 4
		la $a0, errorMsg_fileTooBig
		syscall
		
		li $v0, 10
		syscall

	error_cantopenfile:
		li $v0, 4
		la $a0, errorMsg_cantOpenFile
		syscall
		
		li $v0, 10
		syscall
	
	error_nofileselected:
		li $v0, 4
		la $a0, errorMsg_noFileSelected
		syscall
		
		li $v0, 10
		syscall
		
	error_missingBracket:
		li $v0, 4
		la $a0, errorMsg_missingBracket
		syscall
		
		li $v0, 1
		move $a0, pc
		syscall
		
		li $v0, 11
		li $a0, '\n'
		syscall
		
		li $v0, 10
		syscall

	# Incrementa il valore. Carattere '+'
	bf_add:
		la $t0, dataSpace
		add $t0, $t0, cursor
		lb $t1, 0($t0)
		addi $t1, $t1, 1
		sb $t1, 0($t0)
		j ExecuteEnd

	# Decrementa il valore. Carattere '-'
	bf_sub:
		la $t0, dataSpace
		add $t0, $t0, cursor
		lb $t1, 0($t0)
		subi $t1, $t1, 1
		sb $t1, 0($t0)
		j ExecuteEnd

	# Sposta il cursore a sinistra. Carattere '<'
	bf_mvleft:
		beq $zero, cursor, ExecuteEnd	# Per evitare di andare in negativo
		subi cursor, cursor, 1
		j ExecuteEnd

	# Sposta il cursore a destra, Carattere '>'
	bf_mvright:
		li $t0, maxDataSpace		# Per evitare di andare oltre
		subi $t0, $t0, 1
		beq $t0, cursor, ExecuteEnd
		
		addi cursor, cursor, 1
		j ExecuteEnd

	# Chiede un carattere in input e lo salva in valore. Carattere ','
	bf_in:
		la $t0, dataSpace
		add $t0, $t0, cursor
		li $v0, 12
		syscall
		sb $v0, 0($t0)
		j ExecuteEnd

	# Stampa il carattere ASCII del valore. Carattere '.'
	bf_out:
		la $t0, dataSpace
		add $t0, $t0, cursor
		lb $t1, 0($t0)
		li $v0, 11
		move $a0, $t1
		syscall
		
		j ExecuteEnd

	# Salta se il valore e' == 0. Carattere '['
	bf_jforw:
		# Carica il dato alla posizione del cursor
		la $t0, dataSpace
		add $t0, $t0, cursor
		lb $t1, 0($t0)
		bnez $t1, ExecuteEnd
		
		la $a0, codeSpace
		move $a1, codeLength
		move $a2, pc
		jal FindMatchingClosingBracket
		
		# Se non e' stata trovata la parentesi la funzione mette il registro $v1 a 1
		bne $zero, $v1, error_missingBracket
		
		move pc, $v0
		j ExecuteEnd

	# Salta se il valore è != 0. Carattere: ']'
	bf_jback:
		# Carica il dato alla posizione del cursor
		la $t0, dataSpace
		add $t0, $t0, cursor
		lb $t1, 0($t0)
		beq $zero, $t1, ExecuteEnd
		
		la $a0, codeSpace
		move $a1, pc
		jal FindMatchingOpeningBracket
		
		# Se non e' stata trovata la parentesi la funzione mette il registro $v1 a 1
		bne $zero, $v1, error_missingBracket
		
		move pc, $v0
		
		j ExecuteEnd
	
	# Esce dal programma con return code del valore alla posizione del cursore. Carattere: '@'
	bf_ext_quit:
		# Carichiamo il return code
		la $t0, dataSpace
		add $t0, $t0, cursor
		lb returnCode, 0($t0)

		j end
	
	# Stampa il valore come intero. Carattere: '!'
	bf_ext_printint:
		la $t0, dataSpace
		add $t0, $t0, cursor
		lb $a0, 0($t0)
		
		li $v0, 1
		syscall
		
		j ExecuteEnd
	
	# Legge un intero. Carattere: '?'
	bf_ext_intinput:
		la $t0, dataSpace
		add $t0, $t0, cursor
		
		li $v0, 5		# Read Integer syscall
		syscall
		sb $v0, 0($t0)
		
		j ExecuteEnd
	
	# Disabilita l'esecuzione di istruzioni fino a quando non viene trovato un '\n'. Carattere: '#'
	bf_ext_enablecomment:
		li isCommentFlag, 1
		j ExecuteEnd
	
	# Ri-abilita l'esecuzione di istruzioni. Carattere: '\n'
	bf_ext_disablecomment:
		li isCommentFlag, 0
		j ExecuteEnd
		

	# This only runs when a file is done
	end:
		# Close the file
		li $v0, 16
		move $a0, $s2
		syscall
		
		li $v0, 4
		la $a0, msg_endExec
		syscall
		
		li $v0, 4
		la $a0, msg_returnCode
		syscall
		
		li $v0, 1
		move $a0, returnCode
		syscall
		
		li $v0, 11
		li $a0, '\n'
		syscall
		
		# Calcoliamo il tempo di esecuzione, e lo stampiamo
		li $v0, 30
		syscall
		
		subu startTime, $a0, startTime
		
		la $a0, msg_runTime
		li $v0, 4
		syscall
		
		move $a0, startTime
		li $v0, 36
		syscall
		
		li $a0, 'm'
		li $v0, 11
		syscall
		
		li $a0, 's'
		li $v0, 11
		syscall
		
		li $a0, '\n'
		li $v0, 11
		syscall
		
		li $v0, 10
		syscall
