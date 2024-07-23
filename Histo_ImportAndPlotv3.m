%% import cochlear histology and make plots

% Load the data from the Excel file
filename = 'C:\Users\cmackey\Documents\CochlearHistology\Cochlea Histology Data plots + blobs .xlsx';
raw_data = readtable(filename, 'Sheet', 'Synapse & IHC Raw Data');

% Filter the data for cases starting with "M"
M_data = raw_data(startsWith(raw_data.Case, 'M'), :);

% Define the groups
M_long = [108, 109, 110, 114, 124, 125];
F_long = [119, 120, 122, 123];
M_short = [117, 118, 121];
control = [103, 104, 111, 112, 113];
includeKiloCaptain = 1;
includeOldCtrlGrp = 1;

% Retrieve data for each group
M_long_data = filter_data(M_data, M_long);
F_long_data = filter_data(M_data, F_long);
M_short_data = filter_data(M_data, M_short);
control_data = filter_data(M_data, control);

% Combine M_long and F_long data
combined_long_data = [M_long_data; F_long_data];

% Calculate mean and SD for combined long group, M_short group, and control group
[combined_long_freqs, combined_long_means, combined_long_sds] = calculate_mean_sd(combined_long_data);
[M_short_freqs, M_short_means, M_short_sds] = calculate_mean_sd(M_short_data);
[control_freqs, control_means, control_sds] = calculate_mean_sd(control_data);

% Include KiloCaptain data in M_short group by averaging at each frequency
if includeKiloCaptain == 1
    for i = 1:length(kilocaptain.freqs)
        freq = kilocaptain.freqs(i);
        kc_syns = kilocaptain.syns(i);
        kc_sds = kilocaptain.sds(i);
        
        % Find the corresponding frequency in M_short data
        idx = find(M_short_freqs == freq);
        
        if ~isempty(idx)
            % Average KiloCaptain data with M_short data
            M_short_means(idx) = (M_short_means(idx) + kc_syns) / 2;
            M_short_sds(idx) = sqrt((M_short_sds(idx)^2 + kc_sds^2) / 2);
        else
            % If the frequency is not present, add it
            M_short_freqs = [M_short_freqs; freq];
            M_short_means = [M_short_means; kc_syns];
            M_short_sds = [M_short_sds; kc_sds];
        end
    end
end

% Plot mean and SD for each group
figure;
hold on;

errorbar(combined_long_freqs, combined_long_means, combined_long_sds, 'o-', 'DisplayName', 'Combined Long');
errorbar(M_short_freqs, M_short_means, M_short_sds, 's-', 'DisplayName', 'M_short');
errorbar(control_freqs, control_means, control_sds, 'd-', 'DisplayName', 'control');

set(gca, 'XScale', 'log');
set(gca, 'XLim', [0.1 50]);
xticks_custom = [0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50, 100];
set(gca, 'XTick', xticks_custom);
set(gca, 'XTickLabel', arrayfun(@num2str, xticks_custom, 'UniformOutput', false));

title('Synaptic Counts');
xlabel('Frequency');
ylabel('Syn per IHC (Mean ± SD)');
legend('Location', 'northeastoutside'); % Move the legend outside the plot
grid on;
hold off;

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
    
    % Convert to numeric if necessary
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
