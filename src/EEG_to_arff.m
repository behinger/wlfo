function EEG_to_arff(EEG,chIx,fnOut)
% chIx should contain X/Y/Confidence
%
if 1 == 0
    EEG_to_arff(EEG,2:4,'test.arff')
end

addpath("lib/deep_em_classifier/feature_extraction/arff_utils")
addpath("lib/deep_em_classifier/feature_extraction/")


metadata = struct();
metadata.width_px = 90;
metadata.height_px = 90;
metadata.width_mm = 1;
metadata.height_mm = 1;
metadata.distance_mm = 0.5;
metadata.extra = {};
attributes = {'time','INTEGER';
              'x','NUMERIC';
              'y','NUMERIC';
              'confidence','NUMERIC'};
data = [EEG.times*1000*1000;EEG.data(chIx,:)];
data = data(:,1:100000);
SaveArff(fnOut,data',metadata,attributes,'relation?')
[fp,fn] =fileparts(fnOut);

% add the annotated data
AnnotateData(fnOut, fullfile(fp,[fn '_feature.arff']))
end