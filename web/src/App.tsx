import { Tab } from "@/components/Tab";
import { LanguageContext } from "./contexts/LanguageContext";
import { useState } from "react";
import type SupportedLangs from "./locales/SupportedLangs";
import { useI18n } from "./hooks/useI18n";
import { Toaster } from "@/components/ui/sonner";

export function App() {
  const [language, setLanguage] = useState<keyof typeof SupportedLangs>("en-US");
  //尽早初始化
  useI18n(language, setLanguage);
  return (
    <>
      <LanguageContext.Provider value={language}>
        <Tab setLanguage={setLanguage} />
        <Toaster />
      </LanguageContext.Provider>
    </>
  )
}

export default App
