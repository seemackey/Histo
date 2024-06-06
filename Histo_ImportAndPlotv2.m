%% import cochlear histology and make plots
clear; clc;

% Load the data from the Excel file
filename = 'C:\Users\cmackey\Documents\CochlearHistology\Cochlea Histology Data plots + blobs .xlsx';
raw_data = readtable(filename, 'Sheet', 'Synapse & IHC Raw Data');

% Display the first few rows of the data
% disp(head(raw_data));

% Filter the data for cases starting with "M"
M_data = raw_data(startsWith(raw_data.Case, 'M'), :);

% Define the groups
M_long = [109, 110, 114, 124, 125];
F_long = [119, 120, 122, 123];
M_short = [117, 118, 121];
control = [111, 112, 113];
includeKiloCaptain = 1;
includeOldCtrlGrp = 1;

% Exclude some of the old controls DOESN'T WORK YET
excluded_macaques = ["M22L_Syn", "M22R_Syn", "M104L_Syn", "M104R_Syn"]; 

% Retrieve data for each group
M_long_data = filter_data(M_data, M_long);
F_long_data = filter_data(M_data, F_long);
M_short_data = filter_data(M_data, M_short);
control_data = filter_data(M_data, control);

kilocaptain.freqs = [0.125
0.25
0.5
1
1.4
2
2.8
4
5.6
8
16
32
];

kilocaptain.syns = [9.465851597
12.55760512
14.24984781
16.0746409
17.29985339
16.24096249
13.78925586
13.37893177
11.69815908
16.55906823
16.12911883
9.821505376
];

kilocaptain.sds = [0.939422064
1.056140995
1.385981526
0.991465081
2.494941214
1.717306545
2.52531103
3.356455532
1.553117292
2.181177619
2.64575297
0.584815837
];

YeOldCtrl.freqs = [0.125
0.25
0.5
1
1.4
2
2.8
4
8
16
32
];

YeOldCtrl.syns = [12.031
14.879
15.95735096
18.95514096
18.70585417
18.36346365
19.22487866
18.19422561
18.12407616
17.61808381
12.34781429
];

YeOldCtrl.sds = [0
0
0.507655362
0.958122905
0.679080045
1.328692358
0.530686651
0.828612609
1.220989778
1.092147176
2.174741647];


%% ANALYSIS
% Calculate mean and SD for each group
[M_long_freqs, M_long_means, M_long_sds] = calculate_mean_sd(M_long_data);
[F_long_freqs, F_long_means, F_long_sds] = calculate_mean_sd(F_long_data);
[M_short_freqs, M_short_means, M_short_sds] = calculate_mean_sd(M_short_data);
[control_freqs, control_means, control_sds] = calculate_mean_sd(control_data);

% Calculate within-case percentage of maximum syn per IHC trends across frequency
[M_long_perc_freqs, M_long_perc_means, M_long_perc_sds] = calculate_percentage_max(M_long_data,'Mlong');
[F_long_perc_freqs, F_long_perc_means, F_long_perc_sds] = calculate_percentage_max(F_long_data,'Flong');
[M_short_perc_freqs, M_short_perc_means, M_short_perc_sds] = calculate_percentage_max(M_short_data,'Mshort');
[control_perc_freqs, control_perc_means, control_perc_sds] = calculate_percentage_max(control_data,'ctrl');

%% PLOTS
% Plot mean and SD for each group
figure;
subplot(2, 1, 1);
hold on;

errorbar(M_long_freqs, M_long_means, M_long_sds, 'o-', 'DisplayName', 'Mlong');
errorbar(F_long_freqs, F_long_means, F_long_sds, 'x-', 'DisplayName', 'Flong');
errorbar(M_short_freqs, M_short_means, M_short_sds, 's-', 'DisplayName', 'Mshort');
errorbar(control_freqs, control_means, control_sds, 'd-', 'DisplayName', 'ctrl');
if includeKiloCaptain == 1
    errorbar(kilocaptain.freqs, kilocaptain.syns, kilocaptain.sds, 'd-', 'DisplayName', 'K&C');
end
if includeOldCtrlGrp == 1
    errorbar(YeOldCtrl.freqs, YeOldCtrl.syns, YeOldCtrl.sds, 'd-', 'DisplayName', 'OldCtrl');
end

set(gca, 'XScale', 'log'); 
set(gca,'XLim',[0.1 50])
% Set x-tick 
xticks_custom = [0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100];
set(gca, 'XTick', xticks_custom);
set(gca, 'XTickLabel', arrayfun(@num2str, xticks_custom, 'UniformOutput', false));

hold off;
title('Synaptic Counts');
xlabel('Frequency');
ylabel('Syn per IHC (Mean ± SD)');
legend;
grid on;

% Plot percentage of maximum syn per IHC trends
subplot(2, 1, 2);
hold on;
errorbar(M_long_perc_freqs, M_long_perc_means, M_long_perc_sds, 'o-', 'DisplayName', 'Mlong');
errorbar(F_long_perc_freqs, F_long_perc_means, F_long_perc_sds, 'x-', 'DisplayName', 'Flong');
errorbar(M_short_perc_freqs, M_short_perc_means, M_short_perc_sds, 's-', 'DisplayName', 'Mshort');
errorbar(control_perc_freqs, control_perc_means, control_perc_sds, 'd-', 'DisplayName', 'ctrl');
set(gca, 'XScale', 'log'); 
set(gca,'XLim',[0.1 50])
% Set x-tick 
set(gca, 'XTick', xticks_custom);
set(gca, 'XTickLabel', arrayfun(@num2str, xticks_custom, 'UniformOutput', false));
title('Percentage of Maximum Synaptic Counts');
xlabel('Frequency');
ylabel('% of Max Syn per IHC');
legend;
grid on;

hold off;


%% FUNCTIONS 
% Function to filter data by case numbers
function filtered_data = filter_data(data, numbers)
    % Convert numbers to strings and create patterns
    patterns = arrayfun(@(x) sprintf('M%d', x), numbers, 'UniformOutput', false);
    
    % Filter data based on patterns
    mask = false(height(data), 1);
    for i = 1:length(patterns)
        mask = mask | contains(data.Case, patterns{i});
    end
    filtered_data = data(mask, :);
end



% Function to calculate mean and SD for each group
function [freqs, means, sds] = calculate_mean_sd(group_data)
    % Convert 'Freq' column to numeric if necessary
    if iscell(group_data.Freq)
        group_data.Freq = cellfun(@str2double, group_data.Freq);
    end
    
    % Convert 'Freq' column to numeric if necessary
    if iscell(group_data.x_Ribbons)
        group_data.x_Ribbons = cellfun(@str2double, group_data.x_Ribbons);
    end
    if iscell(group_data.x_IHCs)
        group_data.x_IHCs = cellfun(@str2double,group_data.x_IHCs);
    end
    if iscell(group_data.UpdatedRibbonCount)
        group_data.UpdatedRibbonCount = cellfun(@str2double, group_data.UpdatedRibbonCount);
    end


    % Ensure no NaN values in 'Freq' column
    group_data = group_data(~isnan(group_data.Freq), :);

    % Get unique frequencies and sort them
    freqs = unique(group_data.Freq);
    [freqs, sortIdx] = sort(freqs);

    % Initialize means and sds arrays
    means = zeros(length(freqs), 1);
    sds = zeros(length(freqs), 1);

    for i = 1:length(freqs)
        freq_data = group_data(group_data.Freq == freqs(i), :);
        
        % Calculate ribbons per IHC
        ribbons_per_ihc = nan(height(freq_data), 1);
        for j = 1:height(freq_data)
            if ~isnan(freq_data.UpdatedRibbonCount(j)) && isnumeric(freq_data.UpdatedRibbonCount(j))
                ribbons_per_ihc(j) = freq_data.UpdatedRibbonCount(j) / freq_data.x_IHCs(j);
            else
                ribbons_per_ihc(j) = freq_data.x_Ribbons(j) / freq_data.x_IHCs(j);
            end
        end

        % Exclude NaNs from the calculations
        ribbons_per_ihc = ribbons_per_ihc(~isnan(ribbons_per_ihc));

        % Calculate mean and standard deviation
        means(i) = mean(ribbons_per_ihc);
        sds(i) = std(ribbons_per_ihc);
    end

    % Sort the means and sds arrays according to sorted frequencies
    means = means(sortIdx);
    sds = sds(sortIdx);
end



% Function to calculate percentage of maximum synaptic counts for each group
function [freqs, perc_means, perc_sds] = calculate_percentage_max(group_data,group_name)
    
    
    % Convert 'Freq' column to numeric if necessary
    if iscell(group_data.Freq)
        group_data.Freq = cellfun(@str2double, group_data.Freq);
    end
    
    % Convert 'Freq' column to numeric if necessary
    if iscell(group_data.x_Ribbons)
        group_data.x_Ribbons = cellfun(@str2double, group_data.x_Ribbons);
    end
    if iscell(group_data.x_IHCs)
        group_data.x_IHCs = cellfun(@str2double,group_data.x_IHCs);
    end
    if iscell(group_data.UpdatedRibbonCount)
        group_data.UpdatedRibbonCount = cellfun(@str2double, group_data.UpdatedRibbonCount);
    end

    % Ensure no NaN values in 'Freq' column
    group_data = group_data(~isnan(group_data.Freq), :);

    % Get unique frequencies and sort them
    freqs = unique(group_data.Freq);
    [freqs, sortIdx] = sort(freqs);

    % Initialize arrays for percentage calculations
    perc_means = zeros(length(freqs), 1);
    perc_sds = zeros(length(freqs), 1);

    % Get unique cases
    cases = unique(group_data.Case);

    % Initialize matrix to store percentages
    perc_matrix = NaN(length(cases), length(freqs));

    % Calculate percentage of maximum for each case
    for c = 1:length(cases)
        case_data = group_data(strcmp(group_data.Case, cases{c}), :);
        
        % Calculate ribbons per IHC
        ribbons_per_ihc = nan(height(case_data), 1);
        for j = 1:height(case_data)
            if ~isnan(case_data.UpdatedRibbonCount(j)) && isnumeric(case_data.UpdatedRibbonCount(j))
                ribbons_per_ihc(j) = case_data.UpdatedRibbonCount(j) / case_data.x_IHCs(j);
            else
                ribbons_per_ihc(j) = case_data.x_Ribbons(j) / case_data.x_IHCs(j);
            end
        end

        % Calculate the maximum ribbons per IHC for this case
        max_ribbons = max(ribbons_per_ihc);

        % Calculate the percentage of the maximum for each frequency
        for i = 1:length(freqs)
            freq_idx = find(case_data.Freq == freqs(i));
            if ~isempty(freq_idx)
                valid_ribbons = ribbons_per_ihc(freq_idx);
                valid_ribbons = valid_ribbons(~isnan(valid_ribbons) & (valid_ribbons ~= 0));
                if ~isempty(valid_ribbons)
                    perc_matrix(c, i) = mean(valid_ribbons) / max_ribbons * 100;
                end
            end
        end
    end

    % Calculate means and standard deviations of the percentages across cases
    for i = 1:length(freqs)
        valid_perc = perc_matrix(~isnan(perc_matrix(:, i)), i);
        perc_means(i) = mean(valid_perc);
        perc_sds(i) = std(valid_perc);
    end

    % Sort the means and sds arrays according to sorted frequencies
    perc_means = perc_means(sortIdx);
    perc_sds = perc_sds(sortIdx);
    
        % Plot individual cases
    figure;
    hold on;
    for c = 1:length(cases)
        plot(freqs, perc_matrix(c, :), 'DisplayName', cases{c});
    end
    set(gca, 'XScale', 'log'); 
    set(gca, 'XLim', [0.1 50]);
    xticks_custom = [0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100];
    set(gca, 'XTick', xticks_custom);
    set(gca, 'XTickLabel', arrayfun(@num2str, xticks_custom, 'UniformOutput', false));
    title(group_name);
    xlabel('Frequency');
    ylabel('% of Max Syn per IHC');
    legend('Location', 'northeastoutside'); % Move the legend outside the plot
    grid on;
    hold off;
    
    
    % Save figures
    filename_base = ['C:\Users\cmackey\Documents\CochlearHistology\percentage_max_synaptic_counts_', group_name];
    saveas(gcf, [filename_base, '.fig']);  % Save as .fig
    print('-djpeg', '-r300', [filename_base, '.jpg']);  % Save as high-resolution .jpg
end
