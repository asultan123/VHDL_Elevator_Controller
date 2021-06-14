import random

def resolve(outUpReq, outDownReq, intReq, currentFloor, up, down):

    targetDirection = 1
    combUpReq = outUpReq | intReq
    combDownReq = outDownReq | intReq

    combUpRequest = format(combUpReq, '09b')
    combDownRequest = format(combDownReq, '09b')

    combUpRequest = "".join(reversed(combUpRequest))
    combDownRequest = "".join(reversed(combDownRequest))

    nearestUp = 0
    nearestDown = 0

    validUp = False
    for nearestUp in range(currentFloor, 9):
        if(combUpRequest[nearestUp] == '1'):
            validUp = True
            break

    validDown = False
    for nearestDown in range(currentFloor,-1,-1):
        if(combDownRequest[nearestDown] == '1'):
            validDown = True
            break

    if up == 1 and down == 0 and validUp:
        nextTarget = nearestUp
        targetDirection = 1
    elif up == 0 and down == 1 and validDown:
        nextTarget = nearestDown
        targetDirection = 0
    else:
        if(validUp and validDown):
            distUp = abs(nearestUp-currentFloor)
            distDown = abs(nearestDown-currentFloor)
            if distUp<distDown:
                nextTarget = nearestUp
                targetDirection = 1
            else:
                nextTarget = nearestDown
                targetDirection = 0
        elif validUp:
            nextTarget = nearestUp
            targetDirection = 1
        elif validDown:
            nextTarget = nearestDown
            targetDirection = 0
        else:
            someoneAboveMe = False
            for nearestAboveMe in range(currentFloor,9):
                if(combUpRequest[nearestAboveMe] == '1'):
                    someoneAboveMe = True
                    targetDirection = 1
                    break
                if(combDownRequest[nearestAboveMe] == '1'):
                    someoneAboveMe = True
                    targetDirection = 0
                    break

            someoneBelowMe = False
            for nearestBelowMe in range(currentFloor,-1,-1):
                if(combUpRequest[nearestBelowMe] == '1'):
                    someoneBelowMe = True
                    targetDirection = 1
                    break
                if(combDownRequest[nearestBelowMe] == '1'):
                    someoneAboveMe = True
                    targetDirection = 0
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

    return (nextTarget, targetDirection)

def getRandomBinaryPatternWithActivityRate(size, activityRate):
    str = ""
    for i in range(0,size):
        str = str + '1' if random.randint(0,100) <= activityRate else str + '0'
    return int(str,2)

if __name__ == '__main__':

    file = open("testVectors_Elevator", 'w')

    for i in range(0,10000):

        print("Generating test : " + str(i))

        activityRate = random.randint(0,100)

        outUpReq = getRandomBinaryPatternWithActivityRate(9,activityRate) & (2**8-2)

        outDownReq = getRandomBinaryPatternWithActivityRate(9,activityRate) & (2**8-2)

        currentFloor = 0

        intReq = getRandomBinaryPatternWithActivityRate(9,activityRate) & ~2**currentFloor

        #print("##################starting State####################")

        combUpInternal = format(outUpReq | intReq, '09b')
        combDownInternal = format(outDownReq | intReq, '09b')

        file.write('#test'+str(i)+'\n')

        file.write(format(outUpReq,'09b')+' '+format(outDownReq,'09b')+' '+format(intReq,'09b')+' '+ '\n')

        #print('combUpInternal: ' + combUpInternal)
        #print('combDownInternal: '+ combDownInternal)
        #print('current floor: ' + str(currentFloor))

        goingUp = False
        goingDown = False
        step = True
        at_target = False

        while(outUpReq!=0 or outDownReq!=0 or intReq!=0 and step):

            #print("######################Iteration#######################")

            # clear requests
            if(at_target):

                if(goingUp):
                    outUpReq = outUpReq & ~2**currentFloor
                elif(goingDown):
                    outDownReq = outDownReq & ~2**currentFloor
                else:
                    outDownReq = outDownReq & ~2**currentFloor
                    outUpReq = outUpReq & ~2**currentFloor

                intReq = intReq & ~2**currentFloor

                file.write(
                    format(outUpReq, '09b') + ' ' + format(outDownReq, '09b') + ' ' + format(intReq, '09b') + ' ' + format(
                        currentFloor, '04b') + '\n')

            #print("vectors after clear")

            combUpInternal = format(outUpReq | intReq, '09b')
            combDownInternal = format(outDownReq | intReq, '09b')

            #print('combUpInternal: ' + combUpInternal)
            #print('combDownInternal: ' + combDownInternal)
            #print('current floor: ' + str(currentFloor))

            # resolve requests

            (target, targetDirection) = resolve(outUpReq,outDownReq,intReq,currentFloor, int(goingUp), int(goingDown))
            #print('next floor: ', str(target))

            # go to target

            if(target>currentFloor):
                goingUp = True
                goingDown = False
                currentFloor = currentFloor + 1
                at_target = False
            elif(target<currentFloor):
                goingDown = True
                goingUp = False
                currentFloor = currentFloor - 1
                at_target = False
            else:
                at_target = True
                goingUp = bool(targetDirection)
                goingDown = not bool(targetDirection)

            if goingUp and not goingDown:
                direction = "up"
            elif goingDown and not goingUp:
                direction = "down"
            elif not goingDown and not goingUp:
                direction = "stopped"
            else:
                raise ValueError('going up and down both true')

            #print('direction : ' + direction)

            step = True





