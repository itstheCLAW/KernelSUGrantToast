interface ApplicationViewProps {
    packageName: string,
    name: string,
}
export function ApplicationView({ name, packageName }: ApplicationViewProps) {
    return (
        <div className="flex items-center min-w-0 pointer-events-none">
            <img src={`ksu://icon/${packageName}`} className="size-8 pointer-events-none"/>
            <div className="ml-1 min-w-0 truncate">{name}</div>
        </div>
    )
}