# A Brainfuck interpreter written in MIPS Assembly
This is an interpreter written in MIPS Assembly for the Brainfuck programming language. This was for a school project and is no longer mantained. Also note that all comments are in Italian. It also adds some extra instructions:
- $ : Reads an integer from input and stores it in the current cursor cell
- ! : Prints the value of the current cursor cell formatted as an integer
- \# : Comments the entire line
- @ : Exit the program and use the current cursor cell value as a return code

### How to use
This project was written using MARS, as such it uses some special syscalls and it may not work on other assemblers. To use with MARS open all the files in the /src folder, set "Assemble all files in directory" in MARS and run. A dialog will appear asking for the file with the Brainfuck code, you can either put a relative path from the position of MARS or an absolute path.

### Credits for the samples
- Hello World: Wikipedia page for Brainfuck lang
- 99Bottles: Eric Bock(sorry, I can't find your website anymore)
- Squares: Daniel B Cristofani (cristofdathevanetdotcom) http://www.hevanet.com/cristofd/brainfuck/
- Fibonacci: http://esoteric.sange.fi/brainfuck/bf-source/prog/fibonacci.txt
- Factorial: sorry, I can't find where I got it anymore