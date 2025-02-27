ANCHOR_KEYSPLIT = "anchor-keysplit"
ANCHOR_IMAGE = "zholme/anchor-unstable:latest"

def split_keys(plan, keystores, public_keys, ids):
    plan.add_service(
        name=ANCHOR_KEYSPLIT,
        config=ServiceConfig{
            image = ANCHOR_IMAGE,
            entrypoint = ["tail", "-f", "/dev/null"]
            # add the files in here
        ),
    )

    result = plan.exec(
        service_name=ANCHOR_KEYSPLIT,
        recipe=ExecRecipe(
        )
    )



    plan.print("todo")




