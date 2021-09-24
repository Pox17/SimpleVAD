clear
global minVar;
global maxSpFl;
global silenceCount;
global minEn;
global enThreshPr;
global releaseCount
global lastOutput
global releaseTemp
%variabile per gestire l'index di file massimo 
N = 5;
%variabile per gestire l'index di file minimo
minIndex = 1;
for fileIndex = minIndex : N
    
    %control parameters
    input_name = sprintf('inputaudio%i.data',fileIndex);
    output_char = sprintf('outputVADCopy%i.txt',fileIndex);
    output_DATA = sprintf('outputDATA%i.data',fileIndex);


    %opening input file
    fid = fopen(input_name, 'r');
    signalInput = fread(fid, inf, 'int8');

    %opening char output file
    outCharFile = fopen(output_char, 'w');
    %opening DATA output file
    outDATAFile = fopen(output_DATA, 'w');
    Fs = 8000;
    length = length(signalInput);
    L = int32((1/Fs)*length*1000);
    fprintf("arrayLength:%i\n",length);
    fprintf("the length of file is: %i ms \n",L);
    releaseCount = 3;
    releaseTemp = releaseCount;
    minVar = 0;
    maxSpFl = 1;
    silenceCount = 1;
    enThreshPr = 200;
    lastOutput = 0;
    output = 0;
    outChar = "0";

    for i = 1:160:size(signalInput)
        fprintf("start of buffer\n")
        bufSize = 159;
        voidBuff = zeros(1,bufSize+1);
        if(length-i < 159) 
            bufSize = length - i;
            
        end
        buff =  signalInput(i:i+bufSize);
        if(bufSize<159)
            buff(bufSize:159)=0;
            fprintf("lastOutput")
        end
        fprintf("campione numero %i\n",i);

        
        if(i<160) 
            minEn = sum(abs(buff).^2);
        end


        outChar = vad(buff,Fs);
        fwrite(outCharFile,outChar);
        if(outChar == "1")

            fwrite(outDATAFile,buff, 'int8')
        else
            if(outChar == "0")
                fwrite(outDATAFile,voidBuff, 'int8')
            end
        end

        fprintf("output funzione: %c \n",outChar);
    end

fclose(fid);
fclose(outDATAFile);
fclose(outCharFile);
clear
end
function[outChar] = vad(buffer,Fs)
    global silenceCount;
    global releaseCount
    global lastOutput
    global releaseTemp
    
    output = vadBuf(buffer,Fs);
    if(output == 1)
        outChar = "1";
    else
        if((output==0) && lastOutput == 1)
            if(releaseTemp > 0)
                outChar = "1";
                releaseTemp = releaseTemp-1;
                output = 1;
                silenceCount = silenceCount+1;
                fprintf("Attento che questo sarebbe rumore\n")
            else
                outChar = "0";
                releaseTemp = releaseCount;
                output = 0;
                silenceCount = silenceCount+1;
            end
        else
            outChar = "0";
        end
    end
    lastOutput = output;
end 
function [output] = vadBuf(curBuffer,Fs)
    global minVar;
    global silenceCount;
    global minEn;
    global enThreshPr;
    enThresh = enThreshPr*log(minEn);
    varThresh = 18;
    response = 0;
    fprintf('buf: [');
    fprintf('%g ', curBuffer);
    fprintf(']\n');
    L = (1/Fs)*length(curBuffer)*1000;
    fprintf("arrayLength:%i\n",length(curBuffer));
    fprintf("the length of file is: %i ms \n",L);
    energy = sum(abs(curBuffer).^2);
    Y = fft(curBuffer);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    variance = var(P1);

    fprintf("variance: %i \n",variance);
    fprintf("energy: %i \n",energy);

    if(energy-minEn > enThresh)
        response = response + 1;
    end

    if(variance-minVar > varThresh)
        response = response + 1;
    end
    if(response > 1)
        output = 1;
    else
        output = 0;
        minVar = ((minVar*silenceCount)+variance)/(silenceCount+1);

        minEn = ((minEn*silenceCount)+energy)/(silenceCount+1);
    end

end
