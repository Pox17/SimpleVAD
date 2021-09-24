# **Semplice algoritmo VAD**

*Read this in other languages: [English](README.en.md).*

### Semplice algoritmo VAD, implementato tramite l'utilizzo di MATLAB come progetto finale per il corso di Reti di Calcolatori della laurea triennale di Ingegneria informatica dell'Università di Padova.

È necessario che sia presente il package: "Statistics and Machine Learning Toolbox" all'interno dell'istanza di MATLAB che esegue il run dell'algoritmo. 
L'algoritmo cicla N file di nome "inputaudioN" come richiesto, durante il run lo script si aspetta che siano presenti tutti gli n file di input con il nome specificato. 
Nel caso in cui si voglia specificare un numero diverso di input è sufficiente cambiare le variabili: "N" riga 11 dello script che imposta l'UPPERBOUND, e "minIndex", riga 13, che imposta il LOWERBOUND. 
Lo script produce in OUTPUT un file per ogni sorgente:
- Un file "outputVADN.txt" contenente la sequenza di 0 e 1 per determinare i pacchetti da tenere e da scartare
