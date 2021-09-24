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
    
    %Nomi file lettura e scrittura 
    input_name = sprintf('inputaudio%i.data',fileIndex);
    output_char = sprintf('outputVAD%i.txt',fileIndex);
    %Apertura file di input e output
    fid = fopen(input_name, 'r');
    outCharFile = fopen(output_char, 'w');
    %lettura segnale dal file
    signalInput = fread(fid, inf, 'int8');
    %Frequenza di campionamento
    Fs = 8000;
    %lunghezza del segnale di input in pacchetti
    length = length(signalInput);
    %lunghezza segnale i millisecondi 
    L = int32((1/Fs)*length*1000);
    fprintf("arrayLength:%i\n",length);
    fprintf("the length of file is: %i ms \n",L);
    %assegnazione valori variabili 
    releaseCount = 3;
    releaseTemp = releaseCount;
    minVar = 0;
    maxSpFl = 1;
    silenceCount = 1;
    enThreshPr = 200;
    lastOutput = 0;
    output = 0;
    outChar = "0";
    %preparazione ciclo analisi pacchetti
    for i = 1:160:size(signalInput)
        
        fprintf("start of buffer\n")
        bufSize = 159;
        %trattamento ultimo pacchetto con dimensione minore di 160
        if(length-i < 159) 
            bufSize = length - i;
            
        end
        %estrapolazione pacchetto
        buff =  signalInput(i:i+bufSize);
        %padding ultimo pacchetto
        if(bufSize<159)
            buff(bufSize:159)=0;
            fprintf("lastOutput")
        end
        fprintf("campione numero %i\n",i);
        %calcolo energia minima sul primo pacchetto
        if(i<160) 
            minEn = sum(abs(buff).^2);
        end
        %calcolo carattere di output
        outChar = vad(buff,Fs);
        %scrittura carattere di output
        fwrite(outCharFile,outChar);
        fprintf("output funzione: %c \n",outChar);
    end
%chiusura file di input e output
fclose(fid);
fclose(outCharFile);
clear
end

%Funzione per la gestione delle variabili aggiornate nel corso dell'analisi
function[outChar] = vad(buffer,Fs)
    global silenceCount;
    global releaseCount
    global lastOutput
    global releaseTemp
    %calcolo dell'output tramite funzione che esegue l'analisi audio
    output = vadBuf(buffer,Fs);
    %Se il risultato dell'algoritmo di analisi è 1 l'output è 1
    if(output == 1)
        outChar = "1";
    else
        
        if((output==0) && lastOutput == 1)
            %se l'output dell'analisi è zero e il valore precedente è 1 
            %valuto se il tempo di rilascio è maggiore di zero e in caso
            %stampo 1 e aggiorno il valore di releaseTemp
            if(releaseTemp > 0)
                outChar = "1";
                releaseTemp = releaseTemp-1;
                output = 1;
                silenceCount = silenceCount+1;
                fprintf("Attento che questo sarebbe rumore\n")
            %se l'output dell'analisi è zero e il valore precedente è 1 
            %valuto se il tempo di rilascio è maggiore di zero e e se non è
            %così stampo 0 e resetto releaseTemp
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
    %aggiorno la threshold di valutazione dell'energia
    enThresh = enThreshPr*log(minEn);
    %threshold utilizzato nella varianza 
    varThresh = 18;
    response = 0;
    fprintf('buf: [');
    fprintf('%g ', curBuffer);
    fprintf(']\n');
    L = (1/Fs)*length(curBuffer)*1000;
    fprintf("arrayLength:%i\n",length(curBuffer));
    fprintf("the length of file is: %i ms \n",L);
    %calcolo energia pacchetto
    energy = sum(abs(curBuffer).^2);
    %Computazione trasformata di fourier
    Y = fft(curBuffer);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    %Calcolo della varianza 
    variance = var(P1);
    fprintf("variance: %i \n",variance);
    fprintf("energy: %i \n",energy);
    %Valutazione energia pacchetto adattando sul valore minimo rispetto
    %alla threshold
    if(energy-minEn > enThresh)
        response = response + 1;
    end
    %Valutazione Varianza pacchetto adattando sul valore rispetto
    %alla threshold
    if(variance-minVar > varThresh)
        response = response + 1;
    end
    %nel caso  in cui entrambi i response siano positivi il pacchetto si
    %considera con attività vocale 
    if(response > 1)
        output = 1;
    else
        %nel caso in cui il pacchetto non sia considerato con attività
        %vocale vengono aggiornate le soglie minime di valutazione
        output = 0;
        minVar = ((minVar*silenceCount)+variance)/(silenceCount+1);

        minEn = ((minEn*silenceCount)+energy)/(silenceCount+1);
    end

end
