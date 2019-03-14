function [ro] = ro_approx(Xcode, dtrec, tau, data)
load(data)
act_time = Xcode(:,1) + dtrec(:,2); % czas przesunięty o poprawkę zegar odbiornika

    for i=1:length(act_time)

        act_constellation = squeeze(tau(:,2,i));
        act_constellation(act_constellation==0) = [];

        for j=1:length(act_constellation)

            % dane z sp3
            prn_num = tau(j,2,i);
            i_sp3 = find((eph(:,2)==prn_num)); 
            X_int = eph(i_sp3,1);
            Y_int = [eph(i_sp3,3) eph(i_sp3,4) eph(i_sp3,5)];

            time_sat = act_time(i) - tau(j,3,i);
            Xs = lagrange(X_int, Y_int, time_sat, 10);          
            Xo = Xcode(i,2:4);
            ro(j,:,i) = [act_time(i) prn_num norm(Xo-Xs)];
            
        end

    end

end

