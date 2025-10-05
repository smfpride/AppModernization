## Build and Deployment Commands

### .NET 8 Build Process (Updated October 2025)

**Primary Build Command:**
```bash
dotnet build
```

**Build with Release Configuration:**
```bash
dotnet build -c Release
```

**Build Specific Project:**
```bash
dotnet build eShopLegacyMVC/eShopLegacyMVC.csproj
```

**Run Tests:**
```bash
dotnet test
```

**Run Application Locally:**
```bash
dotnet run --project eShopLegacyMVC/eShopLegacyMVC.csproj
```

**Build Process Notes:**
- Project migrated to .NET 8 SDK-style format
- Uses `dotnet` CLI instead of MSBuild
- Cross-platform compatible (Windows, Linux, macOS)
- Automatic package restoration

**Package Restoration:**
```bash
dotnet restore
```

### Legacy .NET Framework Build Process (Deprecated)

**Historical Build Command:**
```powershell
& "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" "eShopLegacyMVC\eShopLegacyMVC.csproj" /p:Configuration=Debug
```

**Note:** .NET Framework 4.7.2 projects have been migrated to .NET 8. The above command is preserved for historical reference only.