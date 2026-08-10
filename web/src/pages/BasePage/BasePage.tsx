import { LanguageContext } from "@/contexts/LanguageContext";
import type SupportedLangs from "@/locales/SupportedLangs";
import { useContext } from "react";
import LanguageSelect from "./components/LanguageSelect";
import { Separator } from "@/components/ui/separator";
import ThemeSelect from "./components/ThemeSelect";
interface BasePageProps {
    setLanguage: (language: keyof typeof SupportedLangs) => void;
}
export default function BasePage({ setLanguage }: BasePageProps) {
    const languageContext = useContext(LanguageContext);
    return (
        <div className="flex flex-col items-center">
            <LanguageSelect setLanguage={setLanguage} languageContext={languageContext} />
            <Separator className="mt-5" />
            <ThemeSelect />
        </div>
    )
}
