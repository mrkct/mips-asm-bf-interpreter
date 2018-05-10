.data

.eqv pc $s0
.eqv cursor $s1
.eqv codeLength $s2
.eqv fileDescriptor $s3

TESTFILE: .asciiz "TestIO.bf\n"

filename: .space 256
msg_chooseFile: .asciiz "Seleziona il file da aprire: "

error_fileTooBig: .asciiz "Il file e' troppo grande per essere eseguito.\n"
error_cantOpenFile: .asciiz "Impossibile aprire il file.\n"

.eqv maxCodeSpace 8192
codeSpace: .space maxCodeSpace		# Space for read code

.eqv maxDataSpace 4096
dataSpace: .space maxDataSpace

.text

li $v0, 54
la $a0, msg_chooseFile
la $a1, filename
li $a2, 256
syscall

# Se non è stato inserito niente oppure se è stato premuto cancella $a1 != 0
bnez $a1, end

# Il dialog aggiunge anche il \n alla fine del filename, 
# che se passato alla syscall open file non fa trovare il file
# bisogna toglierlo quindi. Questo pezzo di codice sostituisce i \n con \0. 
# Tanto i \n non sono validi nei filename

la $t0, filename
li $t1, '\n'

FilterNewlineLoopStart:
lb $t2, 0($t0)

li $v0, 11
move $a0, $t2
syscall

bne $t2, $t1, FilterNewlineLoopEnd
li $t1, '\0'
sb $t1, 0($t0)
j FilterNewlineLoopExit

FilterNewlineLoopEnd:
addi $t2, $t2, 1
j FilterNewlineLoopStart

FilterNewlineLoopExit:

la $t0, filename

li $v0, 4
la $a0, filename
syscall

#la $t0, TESTFILE

# Open source code file
li $v0, 13
move $a0, $t0
li $a1, 0
li $a2, 0
syscall
move fileDescriptor, $v0

bltz fileDescriptor, error_cantopenfile

readfile:
li $v0, 14
move $a0, fileDescriptor
la $a1, codeSpace
li $a2, maxCodeSpace
syscall

move codeLength, $v0

# Stampa la lunghezza del file caricato
# li $v0, 1
# move $a0, codeLength
# syscall

# li $v0, 4
# la $a0, debugCodeLen
# syscall



# Interpreta ed esegui
li pc, 0
exec:
la $t1, codeSpace
add $t1, $t1, pc
lb $t0, 0($t1)

# Stampa il carattere di istruzione
#li $v0, 11
#move $a0, $t0
#syscall

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

interp_end:
addi pc, pc, 1

beq pc, codeLength, end
j exec

# Messaggi di errore
error_filetoobig:
li $v0, 4
la $a0, error_fileTooBig
syscall
j end

error_cantopenfile:
li $v0, 4
la $a0, error_cantOpenFile
syscall
j end

# Run when a '+' is found
bf_add:
la $t0, dataSpace
add $t0, $t0, cursor
lb $t1, 0($t0)
addi $t1, $t1, 1
sb $t1, 0($t0)
j interp_end

# Run when a '-' is found
bf_sub:
la $t0, dataSpace
add $t0, $t0, cursor
lb $t1, 0($t0)
subi $t1, $t1, 1
sb $t1, 0($t0)
j interp_end

# Run when a '<' is found
bf_mvleft:
subi cursor, cursor, 1
j interp_end

# Run when a '>' is found
bf_mvright:
addi cursor, cursor, 1
j interp_end

# Runs when a ',' is found
bf_in:
la $t0, dataSpace
add $t0, $t0, cursor
li $v0, 12
syscall
sb $v0, 0($t0)
j interp_end

# Runs when a '.' is found
bf_out:
la $t0, dataSpace
add $t0, $t0, cursor
lb $t1, 0($t0)
li $v0, 11
move $a0, $t1
syscall
j interp_end

#Runs when a '[' is found
bf_jforw:
j interp_end

# Runs when a ']' is found
bf_jback:
j interp_end

# This only runs when a file is done
end:
# Close the file
li $v0, 16
move $a0, $s2
syscall