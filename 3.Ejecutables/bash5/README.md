b64 converts 3 bytes into 4 6bitsBytes

Bytes A B C are transformed in

aaaaaa aabbbb bbbbcc cccccc

3 half bytes X Y Z are contained in 2 6bitsBytes

xxxxyy yyzzzz

We decode groups of two bytes

if zzzz is . we ignore it

if yyyy and zzzz are . we ignore them


