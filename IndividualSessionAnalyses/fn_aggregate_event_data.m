function [ aggregate_peri_event_data_struct ] = fn_aggregate_event_data( data_table )
% 
nan_handling = 'omitnan';%5 includenan or omitnan
processing_dim = 1;
std_weight = 0;
alpha = 0.05; % for confidence interval halfwidth

% now just aggregate over the data
aggregate_peri_event_data_struct.median = median(data_table, processing_dim, nan_handling);
aggregate_peri_event_data_struct.max = max(data_table, [], processing_dim, nan_handling);
aggregate_peri_event_data_struct.min = min(data_table, [], processing_dim, nan_handling);
aggregate_peri_event_data_struct.mean = mean(data_table, processing_dim, nan_handling);
aggregate_peri_event_data_struct.std = std(data_table, std_weight, processing_dim, nan_handling);
aggregate_peri_event_data_struct.n = sum(~isnan(data_table), processing_dim);
aggregate_peri_event_data_struct.cihw = calc_cihw(aggregate_peri_event_data_struct.std, aggregate_peri_event_data_struct.n, alpha);


return
end


