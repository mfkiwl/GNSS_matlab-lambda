function [] = codepos(X,

clear;
format long

% tu przykladowe dl pierwszej epoki z pliku joz23280.10o
prn = [  25;  17; 15; 2; 32; 19; 14; 12; 24; 6]; % trzecia epoka trzeci dzie� 

% eph --> readsp3

% potrzebne stale; nie pojawiaja sie na ekranie bo komenda zakonczona znakiem ';'
vc = 299792458; % predkosc swiatla [m/s];
a_maj = 6378137;
fodw = 298.2572221;

f1=1575420000;
f2=1227600000;

% tablica P12 zawiera w pierwszej kolumnie obserwacje C1, w drugiej P2
% przyklad dla pierwszej epoki z pliku joz23280.10o
P12 =[ 

     ];
% 
% Bp = [
%     -0.856
%     0.893
%     1.437 
%     -1.269
%     1.545
%     -2.291
%     -0.597
%     0.942
%     1.083
%     0.906
% ];
 
% Wspolczynniki do kombinacji liniowej
alfa13= f1^2/(f1^2-f2^2);
alfa23=-f2^2/(f1^2-f2^2);


P3= P12(:,1)*alfa13 + P12(:,2)*alfa23 ;  %2.546*Bp*10^-9*vc %cz�on z Bp kodowe opoznienie sprz�towe

% czas obserwacji, w sekundach tygodnia GPS
tobs=3*86400 + 60; % nalezy policzyc dla swojej epoki, tu dla pierwszej
epoch=tobs;

% przyblizony czas propagacji sygnalu
tau=0.07;
dtrec=0;

%trzecia epoka z plikuu joz283 - �roda

% Wspolrzedne joz2 z pliku rinex (wektor pionowy, symbol ' oznacza transpoze)
Xapr=[3664879.2453  1409190.4085  5009617.5512]';

X=Xapr;

for jj=1:3

   [B, L, H] = togeod(a_maj, fodw, X(1), X(2), X(3));

   [nsat,ncol]=size(prn);

   isat=0;

    for ii=1:nsat % petla po wszystkich satelitach

       if (jj > 1)
           tau = (geom(ii))/vc;
       end

% wczytanie do wektora 'Xs' wspolrzednych kolejnych satelitow na moment tobs-tau
% w zmiennej dtsat znajduje sie poprawka do zeg. satelity
       [Xs, dtsat]   = wspsat(prn(ii), eph, tobs+dtrec-tau);
       [Xs1, dtsat1]   = wspsat(prn(ii), eph, tobs+dtrec-tau +0.1);

% Korekcja wsp. satelity z powodu obrotu Ziemi, skorzystać z procedury e_r_corr(tau, Xs)
       Xsat  = e_r_corr(tau, Xs);
       Xsat1  = e_r_corr(tau, Xs1);
       
% !!!! Policzyć prędkość satelity
       V = (Xsat1 - Xsat) / 0.1

% azymut, wysokosc nad horyzontem oraz odleglosc do satelity
       [azymut(ii), wys(ii), geom(ii)] = topocent(X, Xsat-X);
       if wys(ii)>=15
           isat=isat+1;
           PACT(isat)=P3(ii);
% !!!! Poprawki do pseudoodległości, które należy uwzględnić:
           drel(ii)= -(2*Xsat'*V)/vc;
           dtropo(ii)=tropo(wys(ii), H);
           dtrec;
%###################
           PCOM(isat) = geom(ii) - dtsat*vc - drel(ii) + dtropo(ii);
           A(isat,1) = -(Xsat(1) - X(1))/geom(ii);
           A(isat,2) = -(Xsat(2) - X(2))/geom(ii);
           A(isat,3) = -(Xsat(3) - X(3))/geom(ii);
           A(isat,4) = 1;
        end
   end % Koniec petli ii=1:nsat
   
   b= PACT' - PCOM';
   x=inv(A'*A)*(A'*b);
   v=A*x-b;
   m0=sqrt(v'*v/(isat-4));
   dtrec = dtrec+x(4)/vc;
   X=X+x(1:3);
end % Koniec petli jj


%doda� DOPy, 

Q = inv(A'*A);
diag=diag(Q);

GDOP = sqrt(sum(diag));
PDOP = sqrt(diag(1)+diag(2)+diag(3));
TDOP = sqrt(diag(4));
DOP = [GDOP PDOP TDOP];

end

