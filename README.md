# x86-Ascii85-and-Base64-Binary-Text-converters

Binary to Text Converter
-Base64
-Ascii85

command structure:
btc -[e/d][64/85] [infile] [outfile]

example:
-encrypt in base64 the file try.dat to try.txt

	btc -e64 try.dat try.txt
	
-decrypt in ascii85 the file try.txt to try.dat

	btc -d85 try.txt try.dat
