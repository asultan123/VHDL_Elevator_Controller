import random

if __name__ == '__main__':

    file = open('testVectors', 'w')

    file.write('# ext.up ext.down int currentFloor up down targetFloor\n')

    for i in range(0, 1000):
        print('wrote testVector no. ' + str(i))

        line = ""

        outUpReq = random.randint(0, 2 ** 8 - 1)

        outDownReq = random.randint(0, 2 ** 9 - 2)

        currentFloor = random.randint(0, 8)

        intReq = random.randint(0, 2 ** 9 - 2) & ~2 ** currentFloor

        # intReq = int('100001',2)
        # outUpReq = int('10011',2)
        # outDownReq  = int('100001001',2)
        # currentFloor = 7


        combUpReq = outUpReq | intReq

        combDownReq = outDownReq | intReq

        outUpRequest = format(outUpReq, '09b')
        outDownRequest = format(outDownReq, '09b')
        internalRequest = format(intReq, '09b')
        combUpRequest = format(combUpReq, '09b')
        combDownRequest = format(combDownReq, '09b')

        # currentFloor = random.randint(0, 8)

        # print('OutUpRequest: ' + outUpRequest)
        # print('OutDownRequest: '+ outDownRequest)
        # print('internalRequest: '+ internalRequest)
        # print('combinedup: '+ combUpRequest)
        # print('combineddown: '+ combDownRequest)
        # print('current floor: ' + str(currentFloor))

        line += outUpRequest + ' ' + outDownRequest + ' ' + internalRequest + ' ' + format(currentFloor, '04b') + ' '

        outUpRequest = "".join(reversed(outUpRequest))
        outDownRequest = "".join(reversed(outDownRequest))
        internalRequest = "".join(reversed(internalRequest))
        combUpRequest = "".join(reversed(combUpRequest))
        combDownRequest = "".join(reversed(combDownRequest))

        # while True:
        #     up = random.randint(0, 1)
        #     down = random.randint(0, 1)
        #     if not (up == down == 1):
        #         break

        up =0
        down =0

        line += str(up) + ' ' + str(down) + ' '

        inferredDirection = 0
        nearestUp = 0
        nearestDown = 0
        nextTarget = 0

        validUp = False
        for nearestUp in range(currentFloor, 9):
            if (combUpRequest[nearestUp] == '1'):
                validUp = True
                break

        validDown = False
        for nearestDown in range(currentFloor, -1, -1):
            if (combDownRequest[nearestDown] == '1'):
                validDown = True
                break

        if up == 1 and down == 0 and validUp:
            nextTarget = nearestUp
            inferredDirection = 'up'
        elif up == 0 and down == 1 and validDown:
            nextTarget = nearestDown
            inferredDirection = 'down'
        else:
            if(validUp and validDown):
                distUp = abs(nearestUp-currentFloor)
                distDown = abs(nearestDown-currentFloor)
                nextTarget = nearestUp if distUp<distDown else nearestDown
            elif validUp:
                nextTarget = nearestUp
            elif validDown:
                nextTarget = nearestDown
            else:
                someoneAboveMe = False
                for nearestAboveMe in range(currentFloor,9):
                    if(combUpRequest[nearestAboveMe] == '1'):
                        someoneAboveMe = True
                        break
                    if(combDownRequest[nearestAboveMe] == '1'):
                        someoneAboveMe = True
                        break

                someoneBelowMe = False
                for nearestBelowMe in range(currentFloor,-1,-1):
                    if(combUpRequest[nearestBelowMe] == '1'):
                        someoneBelowMe = True
                        break
                    if(combDownRequest[nearestBelowMe] == '1'):
                        someoneAboveMe = True
                        break

                distUp = abs(nearestAboveMe-currentFloor)
                distDown = abs(nearestBelowMe-currentFloor)

                if someoneAboveMe and someoneBelowMe:
                    if distUp<distDown:
                        nextTarget = nearestAboveMe
                    else:
                        nextTarget = nearestBelowMe
                elif someoneAboveMe:
                    nextTarget = nearestAboveMe
                elif someoneBelowMe:
                    nextTarget = nearestBelowMe
                else:
                    nextTarget = currentFloor


        # print('Inferred Direction: '+inferredDirection)
        # print('Next Target: '+ str(nextTarget))

        line += format(nextTarget, '04b') + '\n'
        file.write(line)