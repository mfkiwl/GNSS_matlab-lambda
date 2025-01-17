function [N_float_info, N_fixed_info] = amb_info(time_interval,obs_types)
const;
load('dane_do_test.mat')
% time_interval = 100;
X1 = X(1,:)'; %SEPT
X2 = X(2,:)'; % SEP2
epochs = gpsSecondsFirst:time_interval:gpsSecondsLast;
fodw = 298.2572221;
tau1 = 0.07;% przybli�ony
tau2 = 0.07;
% do stochastycznego
ac = 0.75; 
sigma = 0.002;

%"C1C" "L1C" "C6C" "L6C" "C5Q" "L5Q" "C7Q" "L7Q" "C8Q" "L8Q"
% obs_types = ["C1C" "L1C" "C6C" "L6C" "C5Q" "L5Q" "C7Q" "L7Q" "C8Q" "L8Q"]; % wyb�r obserwacji 
phase_freq = [fE1 fE6 fE5 fE7 fE8];
system = 'E';
[sysPrefix, ~] = sysGNSS(system);
fail_sats = [20 22 14 18]; % odbierany by� sygna� z 220 w obs a w efemerydach go nie ma nawet
% ewentualnie 214 i 218
[~, ~, H1] = togeod(a, fodw, X1(1), X1(2), X1(3));
[~, ~, H2] = togeod(a, fodw, X2(1), X2(2), X2(3));

N_float_info = nan(length(epochs), 40, 5);
N_fixed_info = nan(length(epochs), 40, 5);

for i=1:length(epochs)
    
    i_epoch = find(cell2mat(obsTable1(:,1))==epochs(i)); % indeks wiersza w obsMatrix
    
    for j=1:length(obs_types)
        
        i_obs = find(string(obsType1(:))==obs_types(j)); % indeks warstwy w obsMatrix
        % konstelacje dla obu odbiornik�w w danej epoce
        act_constellation_1 = find(~isnan(obsMatrix1(i_epoch,:,i_obs))); 
        act_constellation_2 = find(~isnan(obsMatrix2(i_epoch,:,i_obs)));
        % cz�� wsp�lna konstelacji
        act_constellation = intersect(act_constellation_1, act_constellation_2, 'stable');
        act_constellation = setdiff(act_constellation, fail_sats); % usuni�cie fail
        nsat = length(act_constellation);
        
        for k=1:nsat
            
%            prn_num = act_constellation(k);
           prn_idx = act_constellation(k);
           prn_num = act_constellation(k) + sysPrefix;
           % interpolacja wsp satelity na epoke
           i_sp3 = find((eph(:,2)==prn_num));
           X_int = eph(i_sp3,1);
           Y_int = [eph(i_sp3,3) eph(i_sp3,4) eph(i_sp3,5)];          
           Xs = lagrange(X_int, Y_int, epochs(i), 10);
           % p�tla do obliczenia tau
           for s=1:2
                if (s > 1)
                   tau1 = (geo1(k))/c;
                   tau2 = (geo2(k))/c;
                end               
                Xs1  = e_r_corr(tau1, Xs');
                Xs2  = e_r_corr(tau2, Xs');
                [az1(k), w1(k), geo1(k)] = topocent(X1, Xs1-X1);
                [az2(k), w2(k), geo2(k)] = topocent(X2, Xs2-X2);              
                Xs1 = Xs1';
                Xs2 = Xs2';
           end
           Xs1 = [];
           Xs2 = [];
           % wsp sat po poprawce zegara odbiornika i tau
           Xs1 = lagrange(X_int, Y_int, epochs(i)-dtrec1(i,2)-tau1, 10);
           Xs2 = lagrange(X_int, Y_int, epochs(i)-dtrec2(i,2)-tau2, 10);
           % znowu obr�t
           Xs1  = e_r_corr(tau1, Xs1');
           Xs2 = e_r_corr(tau2, Xs2');
           %ostateczne warto�ci azymutu, wysoko�ci, odleglosci i tropo
           [azymut1(k), wys1(k), geom1(k)] = topocent(X1, Xs1-X1);
           [azymut2(k), wys2(k), geom2(k)] = topocent(X2, Xs2-X2);
           dtropo1(k)=tropo(wys1(k), H1);
           dtropo2(k)=tropo(wys2(k), H2);
           u(k,:) = (Xs2 - X2)/geom2(k); % wersory u
           C(k) = (1+ac/sind(wys2(k)))^2 * sigma^2; % do stochastycznego
           
           obs1(k) = obsMatrix1(i_epoch, prn_idx, i_obs);
           obs2(k) = obsMatrix2(i_epoch, prn_idx, i_obs);
           
           % satelita referencyjny 
           if k==nsat
               sat_ref1 = find_ref_sat(wys1);
               sat_ref2 = find_ref_sat(wys2);
               %sprawdzenie czy obserwuje wszystkie sygna�y
               % ustawienie na pierwszym miejscu w obserwacjach
               while 1                 
                   if any(isnan(obsMatrix1(i, sat_ref1,:)))                 
                       wys11(sat_ref1) = [];
                       sat_ref1 = find_ref_sat(wys11);
                       sat_ref1 = find(wys1==wys11);                       
                   elseif any(isnan(obsMatrix2(i, sat_ref2,:)))
                       wys22(sat_ref2) = [];
                       sat_ref2 = find_ref_sat(wys22);
                       sat_ref2 = find(wys2==wys22);
                   end                  
                   if all(~isnan(obsMatrix1(i, sat_ref1,:))) && all(~isnan(obsMatrix2(i, sat_ref2,:)))
                       break
                   end
                end
               
               obs1([1 sat_ref1]) = obs1([sat_ref1 1]);
               obs2([1 sat_ref2]) = obs2([sat_ref2 1]);

               dtropo1([1 sat_ref1]) = dtropo1([sat_ref1 1]);
               dtropo2([1 sat_ref2]) = dtropo2([sat_ref2 1]);

               geom1([1 sat_ref1]) = geom1([sat_ref1 1]);
               geom2([1 sat_ref2]) = geom2([sat_ref2 1]);

               wys1([1 sat_ref1]) = wys1([sat_ref1 1]);
               wys2([1 sat_ref2]) = wys2([sat_ref2 1]);

               u([1 sat_ref2],:) = u([sat_ref2 1],:);
               C([1 sat_ref2]) = C([sat_ref2 1]);
            end             
           end        
                      
        % zapis obserwacji do odpowiedniej tablicy wed�ug typu
        if string(obs_types(j)) == "C1C" || string(obs_types(j)) == "L1C"
            % CODE
            if string(obs_types(j)) == "C1C"
                a = obs1; 
                b = obs2;
                dtropo1 = dtropo1;
                dtropo2 = dtropo2;
                geom1 = geom1;
                geom2 = geom2;
                u = u;
                C_c = C*2500; %%%%%
                single_diff = (b - a)';
                single_diff_tropo = (dtropo2 - dtropo1)';
                single_diff_geom = (geom2 - geom1)';
                d_c = design_matrix(length(single_diff)); %%%%%%
                double_diff = d_c*single_diff;
                double_diff_tropo = d_c*single_diff_tropo;
                double_diff_geom = d_c*single_diff_geom;
                du_c = d_c * u; 

                L_c = [double_diff];
                T_c = [double_diff_tropo];
                R_c = [double_diff_geom];
                               
            elseif string(obs_types(j)) == "L1C"
                a = obs1; 
                b = obs2;
                dtropo1 = dtropo1;
                dtropo2 = dtropo2;
                geom1 = geom1;
                geom2 = geom2;
                u = u;
                C_L = C*2500;
                single_diff = (b - a)';
                single_diff_tropo = (dtropo2 - dtropo1)';
                single_diff_geom = (geom2 - geom1)';
                d_L = design_matrix(length(single_diff));
                double_diff = d_L*single_diff*(c/phase_freq(1));
                double_diff_tropo = d_L*single_diff_tropo;
                double_diff_geom = d_L*single_diff_geom;
                du_L = d_L * u; 

                L_L = [double_diff];
                T_L = [double_diff_tropo];
                % ?????
                R_L = [double_diff_geom];
                %macierz B
                B_L = eye(length(double_diff))*(c/phase_freq(1));
                const_L = act_constellation;
                
                L = [L_L; L_c];
                T = [T_L; T_c];
                R = [R_L; R_c];
                L = L - R - T;
                B1 = blkdiag(B_L);
                B0 = zeros(size(B1));
                B = [B1; B0];

                C0 = blkdiag(diag(C_L), diag(C_c));

                D = blkdiag(d_L, d_c);
                DU = [du_L; du_c];

                CL = 2 * D * C0 * D';

                ATCA = DU' * (CL)^-1 * DU;
                ATCB = DU' * (CL)^-1 * B;
                BTCA = B' * (CL)^-1 * DU;
                BTCB = B' * (CL)^-1 * B;

                ATCL = DU' * (CL)^-1 * L;
                BTCL = B' * (CL)^-1 * L;

                M1 = [ATCA ATCB; BTCA BTCB];
                M2 = [ATCL; BTCL];

                xN = M1^-1 * M2;
                x_float(:,i) = xN(1:3);
                N_float = xN(4:length(xN));
                
                for n=1:length(N_float)
                    N_float_info(i,const_L(n),1) = N_float(n);
                end
                
                Cv = M1^-1; 
                Cx = Cv(1:3,1:3);
                Cn = Cv(4:length(xN),4:length(xN));
                CxN = Cv(1:3, 4:length(xN));
                CNx = Cv(4:length(xN),1:3);
                Dx_fixed = Cx - CxN*Cn^-1 * CNx;
                % LAMBDA
                [N_fixed,sqnorm(i,:),Ps(i),Qzhat,~,nfixed(i),mu(i)]=LAMBDA(N_float,Cn);  %

                N_fixed1 = N_fixed(:,1); % pierwsza kolumna z Nfixed
                
                for n=1:length(N_fixed1)
                    N_fixed_info(i,const_L(n),1) = N_fixed1(n);
                end

                % obliczenei x fixed
                x_fixed(:,i) = x_float(:,i) - CxN*Cn^-1 * (N_float - N_fixed1);
                % ratio 
                ratio_L1 = sqnorm(:,2)./sqnorm(:,1);
                
            end
            
            


        elseif string(obs_types(j)) == "C6C" || string(obs_types(j)) == "L6C"
            % CODE
            if string(obs_types(j)) == "C6C"
                a = obs1; 
                b = obs2;
                dtropo1 = dtropo1;
                dtropo2 = dtropo2;
                geom1 = geom1;
                geom2 = geom2;
                u = u;
                C_c = C*2500; %%%%%
                single_diff = (b - a)';
                single_diff_tropo = (dtropo2 - dtropo1)';
                single_diff_geom = (geom2 - geom1)';
                d_c = design_matrix(length(single_diff)); %%%%%%
                double_diff = d_c*single_diff;
                double_diff_tropo = d_c*single_diff_tropo;
                double_diff_geom = d_c*single_diff_geom;
                du_c = d_c * u; 

                L_c = [double_diff];
                T_c = [double_diff_tropo];
                R_c = [double_diff_geom];
                               
            elseif string(obs_types(j)) == "L6C"
                a = obs1; 
                b = obs2;
                dtropo1 = dtropo1;
                dtropo2 = dtropo2;
                geom1 = geom1;
                geom2 = geom2;
                u = u;
                C_L = C*2500;
                single_diff = (b - a)';
                single_diff_tropo = (dtropo2 - dtropo1)';
                single_diff_geom = (geom2 - geom1)';
                d_L = design_matrix(length(single_diff));
                double_diff = d_L*single_diff*(c/phase_freq(2));
                double_diff_tropo = d_L*single_diff_tropo;
                double_diff_geom = d_L*single_diff_geom;
                du_L = d_L * u; 

                L_L = [double_diff];
                T_L = [double_diff_tropo];
                % ?????
                R_L = [double_diff_geom];
                %macierz B
                B_L = eye(length(double_diff))*(c/phase_freq(2));
                const_L = act_constellation;
                
                L = [L_L; L_c];
                T = [T_L; T_c];
                R = [R_L; R_c];
                L = L - R - T;
                B1 = blkdiag(B_L);
                B0 = zeros(size(B1));
                B = [B1; B0];

                C0 = blkdiag(diag(C_L), diag(C_c));

                D = blkdiag(d_L, d_c);
                DU = [du_L; du_c];

                CL = 2 * D * C0 * D';

                ATCA = DU' * (CL)^-1 * DU;
                ATCB = DU' * (CL)^-1 * B;
                BTCA = B' * (CL)^-1 * DU;
                BTCB = B' * (CL)^-1 * B;

                ATCL = DU' * (CL)^-1 * L;
                BTCL = B' * (CL)^-1 * L;

                M1 = [ATCA ATCB; BTCA BTCB];
                M2 = [ATCL; BTCL];

                xN = M1^-1 * M2;
                x_float(:,i) = xN(1:3);
                N_float = xN(4:length(xN));
                
                for n=1:length(N_float)
                    N_float_info(i,const_L(n),2) = N_float(n);
                end
                
                Cv = M1^-1; 
                Cx = Cv(1:3,1:3);
                Cn = Cv(4:length(xN),4:length(xN));
                CxN = Cv(1:3, 4:length(xN));
                CNx = Cv(4:length(xN),1:3);
                Dx_fixed = Cx - CxN*Cn^-1 * CNx;
                % LAMBDA
                [N_fixed,sqnorm(i,:),Ps(i),Qzhat,~,nfixed(i),mu(i)]=LAMBDA(N_float,Cn);  %

                N_fixed1 = N_fixed(:,1); % pierwsza kolumna z Nfixed
                
                for n=1:length(N_fixed1)
                    N_fixed_info(i,const_L(n),2) = N_fixed1(n);
                end

                % obliczenei x fixed
                x_fixed(:,i) = x_float(:,i) - CxN*Cn^-1 * (N_float - N_fixed1);
                % ratio 
                ratio_L1 = sqnorm(:,2)./sqnorm(:,1);
                
            end
            
        elseif string(obs_types(j)) == "C5Q" || string(obs_types(j)) == "L5Q"
            % CODE
            if string(obs_types(j)) == "C5Q"
                a = obs1; 
                b = obs2;
                dtropo1 = dtropo1;
                dtropo2 = dtropo2;
                geom1 = geom1;
                geom2 = geom2;
                u = u;
                C_c = C*2500; %%%%%
                single_diff = (b - a)';
                single_diff_tropo = (dtropo2 - dtropo1)';
                single_diff_geom = (geom2 - geom1)';
                d_c = design_matrix(length(single_diff)); %%%%%%
                double_diff = d_c*single_diff;
                double_diff_tropo = d_c*single_diff_tropo;
                double_diff_geom = d_c*single_diff_geom;
                du_c = d_c * u; 

                L_c = [double_diff];
                T_c = [double_diff_tropo];
                R_c = [double_diff_geom];
                               
            elseif string(obs_types(j)) == "L5Q"
                a = obs1; 
                b = obs2;
                dtropo1 = dtropo1;
                dtropo2 = dtropo2;
                geom1 = geom1;
                geom2 = geom2;
                u = u;
                C_L = C*2500;
                single_diff = (b - a)';
                single_diff_tropo = (dtropo2 - dtropo1)';
                single_diff_geom = (geom2 - geom1)';
                d_L = design_matrix(length(single_diff));
                double_diff = d_L*single_diff*(c/phase_freq(3));
                double_diff_tropo = d_L*single_diff_tropo;
                double_diff_geom = d_L*single_diff_geom;
                du_L = d_L * u; 

                L_L = [double_diff];
                T_L = [double_diff_tropo];
                % ?????
                R_L = [double_diff_geom];
                %macierz B
                B_L = eye(length(double_diff))*(c/phase_freq(3));
                const_L = act_constellation;
                
                L = [L_L; L_c];
                T = [T_L; T_c];
                R = [R_L; R_c];
                L = L - R - T;
                B1 = blkdiag(B_L);
                B0 = zeros(size(B1));
                B = [B1; B0];

                C0 = blkdiag(diag(C_L), diag(C_c));

                D = blkdiag(d_L, d_c);
                DU = [du_L; du_c];

                CL = 2 * D * C0 * D';

                ATCA = DU' * (CL)^-1 * DU;
                ATCB = DU' * (CL)^-1 * B;
                BTCA = B' * (CL)^-1 * DU;
                BTCB = B' * (CL)^-1 * B;

                ATCL = DU' * (CL)^-1 * L;
                BTCL = B' * (CL)^-1 * L;

                M1 = [ATCA ATCB; BTCA BTCB];
                M2 = [ATCL; BTCL];

                xN = M1^-1 * M2;
                x_float(:,i) = xN(1:3);
                N_float = xN(4:length(xN));
                
                for n=1:length(N_float)
                    N_float_info(i,const_L(n),3) = N_float(n);
                end
                
                Cv = M1^-1; 
                Cx = Cv(1:3,1:3);
                Cn = Cv(4:length(xN),4:length(xN));
                CxN = Cv(1:3, 4:length(xN));
                CNx = Cv(4:length(xN),1:3);
                Dx_fixed = Cx - CxN*Cn^-1 * CNx;
                % LAMBDA
                [N_fixed,sqnorm(i,:),Ps(i),Qzhat,~,nfixed(i),mu(i)]=LAMBDA(N_float,Cn);  %

                N_fixed1 = N_fixed(:,1); % pierwsza kolumna z Nfixed
                
                for n=1:length(N_fixed1)
                    N_fixed_info(i,const_L(n),3) = N_fixed1(n);
                end

                % obliczenei x fixed
                x_fixed(:,i) = x_float(:,i) - CxN*Cn^-1 * (N_float - N_fixed1);
                % ratio 
                ratio_L1 = sqnorm(:,2)./sqnorm(:,1);
                
            end
            
        elseif string(obs_types(j)) == "C7Q" || string(obs_types(j)) == "L7Q"
            % CODE
            if string(obs_types(j)) == "C7Q"
                a = obs1; 
                b = obs2;
                dtropo1 = dtropo1;
                dtropo2 = dtropo2;
                geom1 = geom1;
                geom2 = geom2;
                u = u;
                C_c = C*2500; %%%%%
                single_diff = (b - a)';
                single_diff_tropo = (dtropo2 - dtropo1)';
                single_diff_geom = (geom2 - geom1)';
                d_c = design_matrix(length(single_diff)); %%%%%%
                double_diff = d_c*single_diff;
                double_diff_tropo = d_c*single_diff_tropo;
                double_diff_geom = d_c*single_diff_geom;
                du_c = d_c * u; 

                L_c = [double_diff];
                T_c = [double_diff_tropo];
                R_c = [double_diff_geom];
                               
            elseif string(obs_types(j)) == "L7Q"
                a = obs1; 
                b = obs2;
                dtropo1 = dtropo1;
                dtropo2 = dtropo2;
                geom1 = geom1;
                geom2 = geom2;
                u = u;
                C_L = C*2500;
                single_diff = (b - a)';
                single_diff_tropo = (dtropo2 - dtropo1)';
                single_diff_geom = (geom2 - geom1)';
                d_L = design_matrix(length(single_diff));
                double_diff = d_L*single_diff*(c/phase_freq(4));
                double_diff_tropo = d_L*single_diff_tropo;
                double_diff_geom = d_L*single_diff_geom;
                du_L = d_L * u; 

                L_L = [double_diff];
                T_L = [double_diff_tropo];
                % ?????
                R_L = [double_diff_geom];
                %macierz B
                B_L = eye(length(double_diff))*(c/phase_freq(4));
                const_L = act_constellation;
                
                L = [L_L; L_c];
                T = [T_L; T_c];
                R = [R_L; R_c];
                L = L - R - T;
                B1 = blkdiag(B_L);
                B0 = zeros(size(B1));
                B = [B1; B0];

                C0 = blkdiag(diag(C_L), diag(C_c));

                D = blkdiag(d_L, d_c);
                DU = [du_L; du_c];

                CL = 2 * D * C0 * D';

                ATCA = DU' * (CL)^-1 * DU;
                ATCB = DU' * (CL)^-1 * B;
                BTCA = B' * (CL)^-1 * DU;
                BTCB = B' * (CL)^-1 * B;

                ATCL = DU' * (CL)^-1 * L;
                BTCL = B' * (CL)^-1 * L;

                M1 = [ATCA ATCB; BTCA BTCB];
                M2 = [ATCL; BTCL];

                xN = M1^-1 * M2;
                x_float(:,i) = xN(1:3);
                N_float = xN(4:length(xN));
                
                for n=1:length(N_float)
                    N_float_info(i,const_L(n),4) = N_float(n);
                end
                
                Cv = M1^-1; 
                Cx = Cv(1:3,1:3);
                Cn = Cv(4:length(xN),4:length(xN));
                CxN = Cv(1:3, 4:length(xN));
                CNx = Cv(4:length(xN),1:3);
                Dx_fixed = Cx - CxN*Cn^-1 * CNx;
                % LAMBDA
                [N_fixed,sqnorm(i,:),Ps(i),Qzhat,~,nfixed(i),mu(i)]=LAMBDA(N_float,Cn);  %

                N_fixed1 = N_fixed(:,1); % pierwsza kolumna z Nfixed
                
                for n=1:length(N_fixed1)
                    N_fixed_info(i,const_L(n),4) = N_fixed1(n);
                end

                % obliczenei x fixed
                x_fixed(:,i) = x_float(:,i) - CxN*Cn^-1 * (N_float - N_fixed1);
                % ratio 
                ratio_L1 = sqnorm(:,2)./sqnorm(:,1);
                
            end
            
        elseif string(obs_types(j)) == "C8Q" || string(obs_types(j)) == "L8Q"
            % CODE
            if string(obs_types(j)) == "C8Q"
                a = obs1; 
                b = obs2;
                dtropo1 = dtropo1;
                dtropo2 = dtropo2;
                geom1 = geom1;
                geom2 = geom2;
                u = u;
                C_c = C*2500; %%%%%
                single_diff = (b - a)';
                single_diff_tropo = (dtropo2 - dtropo1)';
                single_diff_geom = (geom2 - geom1)';
                d_c = design_matrix(length(single_diff)); %%%%%%
                double_diff = d_c*single_diff;
                double_diff_tropo = d_c*single_diff_tropo;
                double_diff_geom = d_c*single_diff_geom;
                du_c = d_c * u; 

                L_c = [double_diff];
                T_c = [double_diff_tropo];
                R_c = [double_diff_geom];
                               
            elseif string(obs_types(j)) == "L8Q"
                a = obs1; 
                b = obs2;
                dtropo1 = dtropo1;
                dtropo2 = dtropo2;
                geom1 = geom1;
                geom2 = geom2;
                u = u;
                C_L = C*2500;
                single_diff = (b - a)';
                single_diff_tropo = (dtropo2 - dtropo1)';
                single_diff_geom = (geom2 - geom1)';
                d_L = design_matrix(length(single_diff));
                double_diff = d_L*single_diff*(c/phase_freq(5));
                double_diff_tropo = d_L*single_diff_tropo;
                double_diff_geom = d_L*single_diff_geom;
                du_L = d_L * u; 

                L_L = [double_diff];
                T_L = [double_diff_tropo];
                % ?????
                R_L = [double_diff_geom];
                %macierz B
                B_L = eye(length(double_diff))*(c/phase_freq(5));
                const_L = act_constellation;
                
                L = [L_L; L_c];
                T = [T_L; T_c];
                R = [R_L; R_c];
                L = L - R - T;
                B1 = blkdiag(B_L);
                B0 = zeros(size(B1));
                B = [B1; B0];

                C0 = blkdiag(diag(C_L), diag(C_c));

                D = blkdiag(d_L, d_c);
                DU = [du_L; du_c];

                CL = 2 * D * C0 * D';

                ATCA = DU' * (CL)^-1 * DU;
                ATCB = DU' * (CL)^-1 * B;
                BTCA = B' * (CL)^-1 * DU;
                BTCB = B' * (CL)^-1 * B;

                ATCL = DU' * (CL)^-1 * L;
                BTCL = B' * (CL)^-1 * L;

                M1 = [ATCA ATCB; BTCA BTCB];
                M2 = [ATCL; BTCL];

                xN = M1^-1 * M2;
                x_float(:,i) = xN(1:3);
                N_float = xN(4:length(xN));
                
                for n=1:length(N_float)
                    N_float_info(i,const_L(n),5) = N_float(n);
                end
                
                Cv = M1^-1; 
                Cx = Cv(1:3,1:3);
                Cn = Cv(4:length(xN),4:length(xN));
                CxN = Cv(1:3, 4:length(xN));
                CNx = Cv(4:length(xN),1:3);
                Dx_fixed = Cx - CxN*Cn^-1 * CNx;
                % LAMBDA
                [N_fixed,sqnorm(i,:),Ps(i),Qzhat,~,nfixed(i),mu(i)]=LAMBDA(N_float,Cn);  %

                N_fixed1 = N_fixed(:,1); % pierwsza kolumna z Nfixed
                
                for n=1:length(N_fixed1)
                    N_fixed_info(i,const_L(n),5) = N_fixed1(n);
                end

                % obliczenei x fixed
                x_fixed(:,i) = x_float(:,i) - CxN*Cn^-1 * (N_float - N_fixed1);
                % ratio 
                ratio_L1 = sqnorm(:,2)./sqnorm(:,1);
                
            end
        end
        
        % czyszczenie przed nast iteracj�
        obs1 = [];
        obs2 = [];
        wys1 = [];
        wys2 = [];
        geom1 = [];
        geom2 = [];
        dtropo1 = [];
        dtropo2 = [];
        u = [];
        C = [];
        
    end

end

end

