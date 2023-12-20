% This file imports an SMI eye-tracking file as well as the corresponding
% EEG file from one subject of the Child Mind database and aligns the two

% Arnaud Delorme, Dec 2013

EEG = pop_loadset('hbn_eye_tracking_data/SAIIT_2AFC_Block1.set');
p = fileparts(which('eeglab'));
EEG.chanlocs = readlocs(fullfile(p, 'functions', 'supportfiles', 'channel_location_files', 'philips_neuro', 'GSN129.sfp'));
EEG.chanlocs(1:3) = []; % remove fiducials

EEG = pop_eegfiltnew(EEG, 0, 40);
EEG = pop_rmbase(EEG, []);
%EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off','WindowCriterion','off','BurstRejection','off','Distance','Euclidian');

EYE = pop_read_smi('hbn_eye_tracking_data/NDARAA075AMK_SAIIT_2AFC_Block1_Samples.txt');

if isfield(EYE.event, 'description') % use for type
    fprintf('Warning: using description field in eye-tracking channel for event type\n')
    for iEvent = 1:length(EYE.event)
        if ~isempty(EYE.event(iEvent).description)
            EYE.event(iEvent).type = deblank(EYE.event(iEvent).description);
        end
    end
end
EYE = eeg_checkset(EYE, 'eventconsistency');
[MERGEDEEG] = eeg_mergechannels(EEG, EYE);

% plot epochs for different types of events
eventTypes = [ {'BlinkL'}    {'BlinkR'}    {'FixationL'}    {'FixationR'}    {'SaccadeL'}    {'SaccadeR'} ];
figure; 
for iEvent = 1:length(eventTypes)
    EEGepoch = pop_epoch( MERGEDEEG, {  eventTypes{iEvent}  }, [-0.5 1], 'epochinfo', 'yes');
    EEGepoch = pop_rmbase(EEGepoch, [-500 0]);
    subplot(2,3,iEvent)
    pop_erpimage(EEGepoch,1, 127,[],[ 'ERPimage for "' eventTypes{iEvent} '" events' ],1,1,{},[],'' ,'yerplabel','\muV','erp','on','cbar','on','topo', { 127 EEG.chanlocs EEG.chaninfo });
    axes(findobj(gcf, 'tag', 'erpimage'));
    clim([-100 100])
end
return

%%
plotEpoch81 = true; % toggle to true to plot epoch type 81 at the beginning (otherwise 101 at the end)

EYE81 = pop_epoch(EYE, { '81'} , [-1 1]);
EEG81 = pop_epoch(EEG, { '81'} , [-1 0.983]); 
MERGEDEEG81 = pop_epoch(MERGEDEEG, { '81'} , [-1.002 0.983]); % only one plotted

EYE101 = pop_epoch(EYE, { '101 '} , [-1 0]);
EEG101 = pop_epoch(EEG, { '101 '} , [-1 -0.022]); 
MERGEDEEG101 = pop_epoch(MERGEDEEG, { '101 '} , [-0.992 -0.023]); % only one plotted

MERGEDEEG81.data(1:129,:) = bsxfun(@minus, MERGEDEEG81.data(1:129,:), mean(MERGEDEEG81.data(1:129,:)')');
MERGEDEEG101.data(1:129,:) = bsxfun(@minus, MERGEDEEG101.data(1:129,:), mean(MERGEDEEG101.data(1:129,:)')');

if plotEpoch81
    MERGETMP = MERGEDEEG81;
    EYETMP   = EYE81;
else
    MERGETMP = MERGEDEEG101;
    EYETMP   = EYE101;
end

figure('position', [1 466 3440 1000], 'color', 'w'); 
subplot(2,1,1); plot(MERGETMP.data(130:end,:)'); %ylim([-1000 1000])
hold on;
yl = ylim;
xlim([1 MERGETMP.pnts])
for iVert = 1:length(MERGETMP.event)
    lat = MERGETMP.event(iVert).latency;
    plot([lat lat], yl, 'k')
end
title( 'Eye data from merged dataset 500 Hz')

if plotEpoch81
    range = 235:235+119;
else
    range = 7340-58:7340;
end
subplot(2,1,2); plot(range, EYE.data(:,range)');
hold on;
yl = ylim;
xlim([range(1) range(end)])
for iVert = 1:length(EYE.event)
    lat = EYE.event(iVert).latency;
    if lat > range(1) && lat < range(end)
        plot([lat lat], yl, 'k')
    end
end
title( 'Continuous eye dataset (time range) 60 Hz - ground truth')
%setfont(gcf, 'fontsize', 16)

% 
% subplot(3,1,2); plot(EYETMP.data');
% hold on;
% yl = ylim;
% xlim([1 EYETMP.pnts])
% for iVert = 1:length(EYETMP.event)
%     lat = EYETMP.event(iVert).latency;
%     plot([lat lat], yl, 'k')
% end
% title( 'Eye dataset epoched - usually not ideal because event shifted')

