clear all, close all
clc;

%% Extraigo datos:
[v, fs] = audioread('interferencias.wav');
[s1, fs] = audioread('pista_01.wav');
[s2, fs] = audioread('pista_02.wav');
[s3, fs] = audioread('pista_03.wav');
[s4, fs] = audioread('pista_04.wav');
[s5, fs] = audioread('pista_05.wav');
Ts = 1/(fs/2);
nfft = 8192; 

%% Grafico espectro
figure('name','Espectro interferencia');
set(gcf, 'units', 'normalized', 'outerposition',[0 0 1 1 ]);
%hold on;
%interferencia
x = v;
fft_x = fft(x);
len_x =  length(x);
fx = (-pi : 2*pi/(len_x-1) : pi) * fs / (2*pi);
plot(fx,fftshift(abs(fft_x)), 'r')
%se?al
y = s1;
fft_y = fft(y);
len_y = length(y);
fy = (-pi : 2*pi/(len_y-1) : pi) * fs / (2*pi);
%plot(fy,fftshift(abs(fft_y)), 'g')

xlim([-4000 4000])
ylim([-10 5000])
title(['Espectro de la interferencia']);
xlabel('Frecuencia $\omega[Hz]$','interpreter','latex')
ylabel('$|V(\omega)|$','interpreter','latex')
% grid minor


%% Calculo M
delta_p=0.08;
delta_s=0.016;

fs= 44100;
delta_w= (150)/fs; 
M = ceil(((-20*log10(sqrt(delta_p* delta_s)) -13) / (14.6 * delta_w))) + 1;
if(mod(M,2)==0)
    M=M+1;
end
N = M-1;

%%% Firpm 
ws=delta_w*fs;
wp=ws;

flancos= @(w)[w-wp , w, w, w+ws];
f = [0 flancos(1400),flancos(2735),flancos(3772), (fs/4)-wp (fs/4) fs/2]/(fs/2);
A = [1  1   0   0   1   1   0   0   1   1   0   0   1   1   0  0];
V = ones(1,floor(length(A)/2));

dp=+inf;
ds=+inf;
figure()
while(dp > 0.08 || ds > 0.016)
    N = N + 2 %N tiene que ser par
    a = zerophase(firpm(N,f,A,V));
    dp = (max(a(150:200))-min(a(150:200)))/2;
    ds = (max(a(300:400))-min(a(300:400)))/2;  
%     [k,N,dp,ds]; debug
    plot(a); grid minor; drawnow limitrate;
end
h=firpm(N,f,A,V);
grid on;
%% Respuesta impulsiva h(n)
w = linspace(2, 2*pi,length(h));
n = 0:length(h)-1;
stem(n,h);
title('Respuesta impulsiva');
xlabel('Muestras')
ylabel('h[n]')
xlim([0,length(h)]);
grid minor

%% Diagrama de polos y ceros
figure
zplane(h)
title('Diagrama de polos y ceros')
grid minor

%% Amplitud A(w) y respuesta en frecuencia H(w)
figure
nfft=8192;
w = linspace(-pi,pi,nfft);
H = fft(h,nfft);
[Aw,w,Phi] = zerophase(h,[1, zeros(1,length(h)-1)],w); %A(w)
hold on
plot(w/pi,fftshift(abs(H)), 'Linewidth', 1); % con frecuencia normalizada: w en [0,2pi)
xlim([0,1])
plot(w/(pi),Aw,'r--','Linewidth', 0.7)
xlabel('Frecuencia angular normalizada \omega/\pi')
legend('|H(w)|','A(w)')
ylim([-0.05,1.05])
grid minor

%% Cantidad de alternancias L = (M-1)/2
aw = zerophase(h,[1, zeros(1,length(h)-1)]); 
n_min = sum(islocalmin(aw));
n_max = sum(islocalmax(aw));
alternancias = (n_min + n_max) + 14 + 2 %7 flancos 

%% Fase
figure
w = linspace(-pi, pi,length(Phi));
plot((w/pi), Phi);% con frecuencia normalizada: w en [0,2pi)
xlabel('Frecuencia angular normalizada \omega/\pi')
ylabel('\phi(\omega)')
xlim([0 1])
title('Fase ');
grid minor

%% Retardo de grupo
figure
[gd,w] = grpdelay(h,nfft);
plot((w/pi), gd);
%ylim([266 267])
xlabel('Frecuencia angular normalizada \omega/\pi');
ylabel('\tau');
title('Retardo de grupo')
grid minor

%% Version contaminada
[v, fs] = audioread('interferencias.wav');
[s, fs] = audioread('pista_02.wav');
x = s(1:length(s)-1)+v(1:length(s)-1);
y = filter(h,[1, zeros(1,length(h)-1)],x);
sound(y, fs)

len_s =  length(x);
fft_s = fft(x);
f_s = (-pi : 2*pi/(len_s-1) : pi) * fs / (2*pi);

len_y =  length(y);
fft_y = fft(y);
fy = (-pi : 2*pi/(len_y-1) : pi) * fs / (2*pi);

figure('name','Espectro interferencia + audio + filtrado');
set(gcf, 'units', 'normalized', 'outerposition',[0 0 1 1 ]);
plot(f_s,fftshift(abs(fft_s)/nfft), '--g', 'Linewidth', 0.7)
xlim([-20000 20000])
hold on
plot(fy,fftshift(abs(fft_y)/nfft), 'r','Linewidth', 1.2)
xlabel('Frecuencia $[Hz]$','interpreter','latex')
ylabel('$|Y(\omega)|$','interpreter','latex')
legend('Se?al con interferencia','Se?al filtrada')
grid minor,box on

%% Verificacion con sound
%sound(v,fs)
%sound(x,fs)
sound(y,fs);
% sound(s,fs)