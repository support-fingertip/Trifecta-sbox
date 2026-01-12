# Trifecta SFDX Structure

This repo contains a minimal Salesforce DX project layout.

Structure created:
- sfdx-project.json
- config/project-scratch-def.json
- force-app/main/default/{aura,classes,lwc,objects,layouts,permissionsets,staticresources,flexipages}
- .forceignore

Notes:
- Add metadata under force-app/main/default as you develop (Apex classes to `classes/`, LWC to `lwc/`, etc).
- Update `sourceApiVersion` in `sfdx-project.json` if you need a different API version.
