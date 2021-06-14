

if __name__ == '__main__':
    binary = format(int("4B047DFA42F2A5D5F61C021A5851E9A309A24FD58086BD1E", 16), '#0194b')
    print(binary)
    print(len(binary))
    binary = binary[2:len(binary)+1]
    print(binary)
    print(len(binary))
    print("\n\n\n")
    datastream_X= ""
    datastream_Y= ""
    for i in range(1,len(binary),2):
        outx = ord(binary[i-1]) - 48
        outy = ord(binary[i]) - 48
        datastream_X  = datastream_X + str(outx)
        datastream_Y = datastream_Y + str(outy)

    print(datastream_X)
    print(datastream_Y)
