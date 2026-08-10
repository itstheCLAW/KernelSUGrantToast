import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";


import { GitBranch } from "lucide-react";

import { useKsu } from "@/hooks/useKsu";

export default function AboutPage() {
    
    
    const { openUrl, vibration, getVersion } = useKsu();
    const versionInfo = getVersion();
    return (
        <div className="flex flex-col items-center gap-2 p-4">
            <h3 className="text-2xl text-center">KernelSU Next Toast</h3>
            <span className="text-center text-sm">Root grant toast for KernelSU Next and forks (KSUN, SukiSU, etc)</span>
            <span className="text-sm text-[gray]">{versionInfo.versionName} ({versionInfo.versionCode})</span>
            <Separator className="mt-2" />
            <span className="text-sm text-center">Original module by <strong>NativeStar</strong></span>
            <span className="text-sm text-center">KSUN fork by <strong>itstheCLAW</strong> &amp; <strong>Claude (Anthropic)</strong></span>
            <Separator className="mt-2" />
            <Button className="mt-2 w-[70%]" onClick={() => {
                vibration("CONFIRM")
                openUrl("https://github.com/NativeStar/KernelSUGrantToast")
            }}>
                <GitBranch />
                Original Repository
            </Button>
        </div>
    )
}
