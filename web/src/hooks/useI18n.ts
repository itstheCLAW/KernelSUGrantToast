import { useCallback, useEffect } from "react";
import type BaseKeys from "@/locales/zhCN";
import SupportedLangs from "@/locales/SupportedLangs";
type SupportedLangsType = keyof typeof SupportedLangs;
export function useI18n(currentLanguage: SupportedLangsType, setContextLanguage?: (language: SupportedLangsType) => void) {
    useEffect(() => {
        //从存储获取
        const storageLang = localStorage.getItem("language");
        if (storageLang && Reflect.has(SupportedLangs, storageLang)) {
            setContextLanguage?.(storageLang as keyof typeof SupportedLangs);
            document.documentElement.lang = storageLang;
            return
        }
        //获取设备语言
        const deviceLang = navigator.language;
        if (Reflect.has(SupportedLangs, deviceLang)) {
            setContextLanguage?.(deviceLang as keyof typeof SupportedLangs);
        }
    }, []);
    const getLang = useCallback((key: keyof typeof BaseKeys) => {
        if (Reflect.has(SupportedLangs, currentLanguage)) {
            return SupportedLangs[currentLanguage][key] ?? "Unknown translate key";
        } else {
            return SupportedLangs["en-US"][key] ?? "Unknown translate key";
        }
    }, [currentLanguage]);
    const resetLanguage = useCallback((setLanguage: (language: keyof typeof SupportedLangs) => void) => {
        localStorage.removeItem("language");
        setLanguage(navigator.language as any);
    }, []);
    return { getLang, resetLanguage }
}