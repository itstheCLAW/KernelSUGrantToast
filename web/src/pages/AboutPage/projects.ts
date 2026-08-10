import type BaseLang from "../../locales/zhCN";
type LangKey = keyof typeof BaseLang;
const Projects: {
    title: string,
    description: LangKey,
    hasI18n: boolean,
    url: string
}[] = [
    {
        title: "Kyouka",
        description: "about.otherProjects.description.kyouka",
        url: "https://github.com/NativeStar/Kyouka",
        hasI18n:false
    },
    {
        title: "SuishoConnector-Windows",
        description: "about.otherProjects.description.connector.windows",
        url: "https://github.com/NativeStar/SuishoConnector-Windows",
        hasI18n:false
    },
    {
        title:"SuishoConnector-Android",
        description:"about.otherProjects.description.connector.android",
        url:"https://github.com/NativeStar/SuishoConnector-Android",
        hasI18n:false
    },
    {
        title:"Ruru Custom",
        description:"about.otherProjects.description.ruru",
        url:"https://github.com/NativeStar/Ruru",
        hasI18n:true
    }
] as const;
export default Projects;