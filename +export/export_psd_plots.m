function params = export_psd_plots(varargin)
    if(nargin == 0)        
        x = DMExportPlots([mfilename('fullpath'),'.plist']);
        params = x.params;
    else
        x = DMExportPlots(varargin{:});
        params = isa(x,'DMExportPlots') && x.status.finished;
    end
end