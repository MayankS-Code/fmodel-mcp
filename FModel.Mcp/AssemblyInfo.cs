using System.Reflection;
using System.Runtime.CompilerServices;
[assembly: InternalsVisibleTo("FModel.Mcp.Tests")]

namespace FModel.Mcp;

internal static class BuildInfo
{
    /// <summary>The project version from &lt;Version&gt; in FModel.Mcp.csproj, without build metadata.</summary>
    public static string Version { get; } =
        (typeof(BuildInfo).Assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion ?? "0.0.0")
        .Split('+')[0];
}
