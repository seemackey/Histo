% cochlear histology analysis
% this script analyzes synaptic ribbon volume data from an idiosyncratic
% spreadsheet
% chase m 2024
% optionally, you can directly import RibbonVolume.mat and skip the
% spreadsheet

%% Import the data from an excel sheet. 
clear;

% Load the Excel file
filename = 'C:\Users\cmackey\Documents\CochlearHistology\IHCRibbonVolData.xlsx';  % Update with your file path
[~, sheets] = xlsfinfo(filename);

% Initialize storage for data
data = struct();

% Read data from each sheet and organize it
for i = 1:length(sheets)
    sheet = sheets{i};
    % Ensure sheet name is treated as a string
    sheetNameStr = string(sheet);

    % Debugging: display the current sheet name
    disp(['Processing sheet: ' sheetNameStr]);

    % Read the first row to get headers
    headers = readcell(filename, 'Sheet', sheet, 'Range', '1:1');

    % Read the rest of the data
    sheetData = readtable(filename, 'Sheet', sheet, 'Range', '2:10000'); % Adjust range as needed
    
    % Extract frequency place and ribbon volumes
    freqPlace = headers;
    ribbonVolumes = table2array(sheetData);

    % Append different voxels within the same case
    uniqueFreqs = unique(string(freqPlace));
    caseData = struct();
    for j = 1:length(uniqueFreqs)
        freq = uniqueFreqs{j};
        % Use strcmp to find matching frequency place headers
        voxelData = ribbonVolumes(:, strcmp(freqPlace, freq));
        validFreqName = matlab.lang.makeValidName(freq);
        
        % Initialize a cell array to handle variable-length data
        voxelDataClean = cell(1, size(voxelData, 2));
        
        % Clean the voxel data by removing NaNs
        for appendcount = 1:size(voxelData, 2)
            cleanedData = voxelData(~isnan(voxelData(:, appendcount)), appendcount);
            voxelDataClean{appendcount} = cleanedData;
        end
        
        % Append cleaned voxel data for this frequency place
        for appendcount = 1:length(voxelDataClean)
            if isfield(caseData, validFreqName)
                caseData.(validFreqName) = [caseData.(validFreqName); voxelDataClean{appendcount}];
            else
                caseData.(validFreqName) = voxelDataClean{appendcount};
            end
        end
    end

    % Create a valid field name for the sheet
    validSheetName = matlab.lang.makeValidName(sheetNameStr);

    % Store the data in the structure
    data.(validSheetName) = caseData;
end

%% Group the data
% Define the groups
M_long = [108,109, 110, 114, 124, 125];
F_long = [119, 120, 122, 123];
M_short = [26, 28, 117, 118, 121];
control = [103, 104, 111, 112, 113];

% Define the new specific ears group
specific_ears = {'x108R', 'x110L', 'x114R', 'x125L', 'x125R', 'x119R', 'x120R'};

groupNames = {'M_long', 'F_long', 'M_short', 'control', 'specific_ears'};
groupedData = struct();

% Group the original groups
for k = 1:length(groupNames) - 1 % Skip the new specific ears group for now
    group = groupNames{k};
    groupCases = eval(group); % Get the case IDs for the current group
    groupedData.(group) = [];

    for caseID = groupCases
        caseIDStr = ['x' num2str(caseID)];
        groupedData.(group).(caseIDStr) = struct();
        
        % Check both L and R versions of the case
        for suffix = ["L", "R"]
            caseName = ['x' num2str(caseID) suffix];
            caseName = join(caseName);
            validCaseName = matlab.lang.makeValidName(caseName);
            if isfield(data, validCaseName)
                groupedData.(group).(caseIDStr).(suffix) = data.(validCaseName);
            end
        end
    end
end

% Group the new specific ears group
groupedData.specific_ears = struct();
for i = 1:length(specific_ears)
    ear = specific_ears{i};
    validEarName = matlab.lang.makeValidName(ear);
    if isfield(data, validEarName)
        groupedData.specific_ears.(validEarName) = data.(validEarName);
    end
end

% Data are now grouped.

%% Analyze the grouped data

groups = {M_long, F_long, M_short, control, specific_ears};

% Initialize a struct to store mean volumes
meanVolumes = struct();

% Loop through each group
for k = 1:length(groupNames)
    group = groupNames{k};
    groupCases = groups{k}; % Get the case IDs for the current group
    allFreqNames = {}; % To store all unique frequency names for this group
    freqData = struct(); % To store volume data by frequency for this group

    % Collect data from each case in the group
    if strcmp(group, 'specific_ears')
        for ear = specific_ears
            earName = ear{1};
            validEarName = matlab.lang.makeValidName(earName);
            if isfield(groupedData.specific_ears, validEarName)
                caseData = groupedData.specific_ears.(validEarName);
                
                % Collect volume data for each frequency place
                freqNames = fieldnames(caseData);
                allFreqNames = [allFreqNames; freqNames]; % Gather all frequency names
                
                for j = 1:length(freqNames)
                    freq = freqNames{j};
                    if isfield(freqData, freq)
                        freqData.(freq) = [freqData.(freq); caseData.(freq)];
                    else
                        freqData.(freq) = caseData.(freq);
                    end
                end
            end
        end
    else
        for caseID = groupCases
            caseIDStr = ['x' num2str(caseID)];
            
            % Check both L and R versions of the case
            for suffix = ["L", "R"]
                if isfield(groupedData.(group), caseIDStr) && isfield(groupedData.(group).(caseIDStr), suffix)
                    caseData = groupedData.(group).(caseIDStr).(suffix);

                    % Collect volume data for each frequency place
                    freqNames = fieldnames(caseData);
                    allFreqNames = [allFreqNames; freqNames]; % Gather all frequency names
                    
                    for j = 1:length(freqNames)
                        freq = freqNames{j};
                        if isfield(freqData, freq)
                            freqData.(freq) = [freqData.(freq); caseData.(freq)];
                        else
                            freqData.(freq) = caseData.(freq);
                        end
                    end
                end
            end
        end
    end

    %  Metrics for each frequency place
    allFreqNames = unique(allFreqNames); % Get unique frequency names
    meanVolumes.(group) = struct();
    for j = 1:length(allFreqNames)
        freq = allFreqNames{j};
        tmpdata = freqData.(freq);
        meanVolumes.(group).(freq) = mean(freqData.(freq), 'omitnan');
        VolumesSD.(group).(freq) = std(tmpdata);
        VolumeIQR.(group).(freq) = iqr(tmpdata);
        VolumeSkew.(group).(freq) = skewness(tmpdata);
        VolumeRange.(group).(freq) = range(tmpdata);
        VolumeTailVar.(group).(freq) = var(tmpdata(floor(0.9*length(tmpdata)):end));
    end
end

%% PLOTTING

% Plot the mean volumes
figure;
subplot(1,4,1)
hold on;
colors = lines(length(groupNames));

for k = 1:length(groupNames)
    group = groupNames{k};
    freqNames = fieldnames(meanVolumes.(group));
    
    % Convert frequency names to numeric values
    freqs = cellfun(@(x) str2double(strrep(x(2:end), '_', '.')), freqNames);
    volumes = cellfun(@(x) meanVolumes.(group).(x), freqNames);
    sds = cellfun(@(x) VolumesSD.(group).(x), freqNames);
    
    % Sort by frequency
    [freqs, sortIdx] = sort(freqs);
    volumes = volumes(sortIdx);
    
    plot(freqs, volumes, '-o', 'Color', colors(k, :), 'DisplayName', group);
%   errorbar(freqs,volumes,sds)
end

xlabel('Frequency (kHz)');
set(gca, 'XScale', 'log'); 
set(gca,'XLim',[0.1 50])
ylabel('Mean Ribbon Volume');
legend('Location', 'best');
title('Mean Ribbon Volume as a Function of Frequency');

% Plot the IQR of volumes
subplot(1,4,2)
hold on;
for k = 1:length(groupNames)
    group = groupNames{k};
    freqNames = fieldnames(VolumeIQR.(group));
    
    % Convert frequency names to numeric values
    freqs = cellfun(@(x) str2double(strrep(x(2:end), '_', '.')), freqNames);
    volumes = cellfun(@(x) VolumeIQR.(group).(x), freqNames);

    % Sort by frequency
    [freqs, sortIdx] = sort(freqs);
    volumes = volumes(sortIdx);
    
    plot(freqs, volumes, '-o', 'Color', colors(k, :), 'DisplayName', group);
end

xlabel('Frequency (kHz)');
set(gca, 'XScale', 'log'); 
set(gca,'XLim',[0.1 50])
ylabel('Ribbon Volume IQR');
legend('Location', 'best');
title('Interquartile Range');

% Plot the skewness of volumes
subplot(1,4,3)
hold on;
for k = 1:length(groupNames)
    group = groupNames{k};
    freqNames = fieldnames(VolumeSkew.(group));
    
    % Convert frequency names to numeric values
    freqs = cellfun(@(x) str2double(strrep(x(2:end), '_', '.')), freqNames);
    volumes = cellfun(@(x) VolumeSkew.(group).(x), freqNames);

    % Sort by frequency
    [freqs, sortIdx] = sort(freqs);
    volumes = volumes(sortIdx);
    
    plot(freqs, volumes, '-o', 'Color', colors(k, :), 'DisplayName', group);
end

xlabel('Frequency (kHz)');
set(gca, 'XScale', 'log'); 
set(gca,'XLim',[0.1 50])
ylabel('Skewness');
legend('Location', 'best');
title('Ribbon Volume Skewness');

% Plot the range of volumes
subplot(1,4,4)
hold on;
for k = 1:length(groupNames)
    group = groupNames{k};
    freqNames = fieldnames(VolumeRange.(group));
    
    % Convert frequency names to numeric values
    freqs = cellfun(@(x) str2double(strrep(x(2:end), '_', '.')), freqNames);
    volumes = cellfun(@(x) VolumeRange.(group).(x), freqNames);

    % Sort by frequency
    [freqs, sortIdx] = sort(freqs);
    volumes = volumes(sortIdx);
    
    plot(freqs, volumes, '-o', 'Color', colors(k, :), 'DisplayName', group);
end

xlabel('Frequency (kHz)');
set(gca, 'XScale', 'log'); 
set(gca,'XLim',[0.1 50])
ylabel('Range');
legend('Location', 'best');
title('Range');
print('RibbonVolSummary7', '-djpeg', '-r300'); % Save as JPEG with 300 dpi resolution

