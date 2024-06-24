% Define groups
groups = {'control', 'M_long', 'M_short', 'F_long'};
numGroups = length(groups);

% Initialize storage for p-values and adjusted p-values
pVals = struct();
adjPVals = struct();
significance = struct();

% Perform KS tests
for i = 1:numGroups
    group = groups{i};
    if strcmp(group, 'control')
        continue; % Skip control group since it's the reference
    end

    % Get subjects in the test group and control group
    testGroupSubjects = fieldnames(groupedData.(group));
    controlSubjects = fieldnames(groupedData.control);
    
    % Collect all frequencies present in both groups
    allFreqNames = [];
    for k = 1:length(controlSubjects)
        subject = controlSubjects{k};
        if isfield(groupedData.control.(subject), 'L')
            allFreqNames = [allFreqNames; fieldnames(groupedData.control.(subject).L)];
        end
        if isfield(groupedData.control.(subject), 'R')
            allFreqNames = [allFreqNames; fieldnames(groupedData.control.(subject).R)];
        end
    end
    for k = 1:length(testGroupSubjects)
        subject = testGroupSubjects{k};
        if isfield(groupedData.(group).(subject), 'L')
            allFreqNames = [allFreqNames; fieldnames(groupedData.(group).(subject).L)];
        end
        if isfield(groupedData.(group).(subject), 'R')
            allFreqNames = [allFreqNames; fieldnames(groupedData.(group).(subject).R)];
        end
    end
    allFreqNames = unique(allFreqNames);

    for j = 1:length(allFreqNames)
        freq = allFreqNames{j};
        controlVolumes = [];
        testGroupVolumes = [];

        % Collect volumes from the control group
        for k = 1:length(controlSubjects)
            subject = controlSubjects{k};
            if isfield(groupedData.control.(subject), 'L') && isfield(groupedData.control.(subject).L, freq)
                controlVolumes = [controlVolumes; groupedData.control.(subject).L.(freq)];
            end
            if isfield(groupedData.control.(subject), 'R') && isfield(groupedData.control.(subject).R, freq)
                controlVolumes = [controlVolumes; groupedData.control.(subject).R.(freq)];
            end
        end

        % Collect volumes from the test group
        for k = 1:length(testGroupSubjects)
            subject = testGroupSubjects{k};
            if isfield(groupedData.(group).(subject), 'L') && isfield(groupedData.(group).(subject).L, freq)
                testGroupVolumes = [testGroupVolumes; groupedData.(group).(subject).L.(freq)];
            end
            if isfield(groupedData.(group).(subject), 'R') && isfield(groupedData.(group).(subject).R, freq)
                testGroupVolumes = [testGroupVolumes; groupedData.(group).(subject).R.(freq)];
            end
        end

        % Check if both control and test group have data for this frequency
        if ~isempty(controlVolumes) && ~isempty(testGroupVolumes)
            % Perform KS test
            [~, p] = kstest2(controlVolumes, testGroupVolumes);
            pVals.(group).(freq) = p;
        else
            pVals.(group).(freq) = NaN; % Assign NaN if there's no data for comparison
        end
    end
end

% Collect all p-values for BH correction
allPvals = [];
freqGroupPairs = {}; % To keep track of frequency-group pairs for reconstruction

for i = 1:numGroups
    group = groups{i};
    if strcmp(group, 'control')
        continue; % Skip control group
    end
    freqNames = fieldnames(pVals.(group));
    for j = 1:length(freqNames)
        if ~isnan(pVals.(group).(freqNames{j}))
            allPvals = [allPvals; pVals.(group).(freqNames{j})];
            freqGroupPairs{end+1} = {freqNames{j}, group}; % Track frequency and group
        end
    end
end

% Apply Benjamini-Hochberg correction
[h, crit_p, adj_ci_cvrg, adjPvals] = fdr_bh(allPvals, 0.05, 'pdep', 'no');

% Assign adjusted p-values and significance back to the struct
for idx = 1:length(freqGroupPairs)
    freqGroup = freqGroupPairs{idx};
    freq = freqGroup{1};
    group = freqGroup{2};
    adjPVals.(freq).(group) = adjPvals(idx);
    significance.(freq).(group) = h(idx); % Store significance flag (1 if significant, 0 if not)
end


%%
% Extract frequencies and groups
groups = {'M_long', 'M_short', 'F_long'};
allFreqNames = unique(allFreqNames); % List of all frequencies from the previous script

% Initialize matrix to store significance flags
sigMatrix = zeros(length(groups), length(allFreqNames));

% Fill the significance matrix
for i = 1:length(groups)
    group = groups{i};
    for j = 1:length(allFreqNames)
        freq = allFreqNames{j};
        if isfield(significance, freq) && isfield(significance.(freq), group)
            sigMatrix(i, j) = significance.(freq).(group); % 1 if significant, 0 otherwise
        end
    end
end

% Create a figure
figure;

% Create a heatmap to visualize the significance matrix
heatmap(allFreqNames, groups, sigMatrix, 'CellLabelColor', 'none');
xlabel('Frequency (kHz)');
ylabel('Group');
title('Significant Differences from Control Across Frequencies');

% Adjust figure settings for better visualization
ax = gca;
ax.XDisplayLabels = strrep(allFreqNames, '_', '.'); % Replace '_' with '.' for clarity
ax.YDisplayLabels = groups;
colorbar off; % Disable color bar since it's binary

% Add custom color settings
caxis([-0.5 1.5]);
colormap([1 1 1; 0 0 1]); % White for non-significant, blue for significant

% Show grid
grid on;

