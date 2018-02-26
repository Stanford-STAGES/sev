function reset_defaults_dlg(fileToReset)

    choice = questdlg({'Click OK to reset setting parameters.';' ';
        ' This may be necessary when copying ';
        ' the SEV to a new computer or when  '
        ' a parameter file becomes corrupted.'; ' '},...
        'Set Defaults', ...
        'OK','Cancel','Cancel');
    % Handle response
    if(strncmp(choice,'OK',2))
        delete(fileToReset);        
        sev_restart();
    end
end