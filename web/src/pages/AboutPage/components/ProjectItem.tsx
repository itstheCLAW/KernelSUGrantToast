import { FieldDescription } from "@/components/ui/field";
interface ProjectItemProps {
    title: string;
    description: string;
}
export default function ProjectItem({description,title}:ProjectItemProps) {
    return (
        <div className="flex flex-col min-w-0">
            <span>{title}</span>
            <FieldDescription className="wrap-break-word break-all">{description}</FieldDescription>
        </div>
    )
}