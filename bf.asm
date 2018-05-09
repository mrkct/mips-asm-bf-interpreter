.data

.eqv pc $s0
.eqv cursor $s1
.eqv codeLength $s2
.eqv fileDescriptor $s3

TESTFILE: .asciiz "brainfuck.bf"

error_fileTooBig: .asciiz "Il file e' troppo grande per essere eseguito.\n"
error_cantOpenFile: .asciiz "Impossibile aprire il file.\n"

debugCodeLen: .asciiz "\nSopra(Code Length)\n"

.eqv maxCodeSpace 8192
codeSpace: .space maxCodeSpace		# Space for read code

.eqv maxDataSpace 4096
dataSpace: .space maxDataSpace

.text

la $t0, TESTFILE

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
li $v0, 1
move $a0, codeLength
syscall

li $v0, 4
la $a0, debugCodeLen
syscall



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

# Stampa valore PC
li $v0, 1
move $a0, pc
syscall

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

bf_add:
la $t0, dataSpace
add $t0, $t0, cursor
lb $t1, 0($t0)
addi $t1, $t1, 1
sb $t1, 0($t0)
j interp_end
bf_sub:
bf_mvleft:
subi cursor, cursor, 1
j interp_end
bf_mvright:
addi cursor, cursor, 1
j interp_end
bf_in:
bf_out:
bf_jforw:
bf_jback:
j interp_end

end:
# Close the file 
li $v0, 16
move $a0, $s2
syscall