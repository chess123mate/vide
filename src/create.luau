local apply = require "./apply"
local flags = require "./flags"

local function create(class_or_instance: string|Instance, properties: { [unknown]: unknown }?): unknown
    local type_ = typeof(class_or_instance)
    if type_ ~= "string" and type_ ~= "Instance" then
        error("create argument #1, expected string or instance, got " .. type_, 2)
    end
    if not properties then
        error("create argument #2, missing properties", 2)
    end

    if type_ == "string" then
        return apply(Instance.new(class_or_instance :: any), properties)
    else
        local clone = class_or_instance:Clone() or error("attempt to clone a non-archivable instance", 0)
        return apply(clone, properties)
    end
end

export type Instances = {
    Folder: Folder,
    BillboardGui: BillboardGui,
    CanvasGroup: CanvasGroup,
    Frame: Frame,
    ImageButton: ImageButton,
    ImageLabel: ImageLabel,
    ScreenGui: ScreenGui,
    ScrollingFrame: ScrollingFrame,
    SurfaceGui: SurfaceGui,
    TextBox: TextBox,
    TextButton: TextButton,
    TextLabel: TextLabel,
    UIAspectRatioConstraint: UIAspectRatioConstraint,
    UICorner: UICorner,
    UIGradient: UIGradient,
    UIGridLayout: UIGridLayout,
    UIListLayout: UIListLayout,
    UISizeConstraint: UISizeConstraint,
    UITextSizeConstraint: UITextSizeConstraint,
    UIScale: UIScale,
    UIPadding: UIPadding,
    UIStroke: UIStroke,
    UIFlexItem: UIFlexItem,
    UIPageLayout: UIPageLayout,
    UITableLayout: UITableLayout,
    VideoFrame: VideoFrame,
    ViewportFrame: ViewportFrame,
    ProximityPrompt: ProximityPrompt,
    UIDragDetector: UIDragDetector,
    Camera: Camera,
    WorldModel: WorldModel,
}

export type function Properties(instance: type?)
    local properties = types.newtable()

    while instance do
        for i, v in instance:properties() do
            local connector = v.read and v.read.tag == "table" and v.read:readproperty(types.singleton("Connect"))
            if connector then
                local params = connector:parameters().head
                if not params then continue end
                local listener = params[2]
                if not listener then continue end
                properties:setproperty(i, types.optional(listener))
            elseif v.write then
                properties:setproperty(i, types.optional(types.unionof(
                    v.write,
                    types.newfunction({}, { head = { v.write } })
                )))
            end
        end

        instance = instance:readparent()
    end

    properties:setindexer(types.number, types.any)

    return properties
end

type Create = <Name>(Name|keyof<Instances>|"", Properties<index<Instances, Name>>) -> index<Instances, Name>

return create :: Create
