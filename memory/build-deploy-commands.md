## Build and Deployment Commands

### .NET Framework Build Process

**Primary Build Command (Working):**
```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" "eShopLegacyMVC\eShopLegacyMVC.csproj" /p:Configuration=Debug
```

**Alternative Build Command (Release):**
```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" "eShopLegacyMVC\eShopLegacyMVC.csproj" /p:Configuration=Release
```

**Build Process Notes:**
- .NET Framework 4.7.2 projects require MSBuild instead of `dotnet build`
- Use full path to MSBuild.exe for consistency across environments
- PowerShell execution requires `&` operator for paths with spaces
- Configuration parameter should match desired build configuration (Debug/Release)

**Failed Attempts (Do Not Use):**
- `dotnet build` - Not compatible with .NET Framework projects
- `msbuild` - Command not found without full path or Developer Command Prompt

**Package Restoration:**
```powershell
nuget restore AppModernization.sln
```