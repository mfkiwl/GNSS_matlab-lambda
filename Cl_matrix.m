function [Cl] = Cl_matrix(C, phase_frequencies, time_interval, data)
load(data)

n = length(phase_frequencies);
epochs = gpsSecondsFirst:time_interval:gpsSecondsLast;

for i=1:length(epochs)
    
    n_obs = cell2mat(cellfun(@size,C(i),'uni',false));
    n_obs = n_obs(1);
    n_obs = n_obs/(n*2);
    d = design_matrix(n*2, n_obs);
    
    Cl{i} =  d * (2*cell2mat(C(i))) * d';
    
end

end

