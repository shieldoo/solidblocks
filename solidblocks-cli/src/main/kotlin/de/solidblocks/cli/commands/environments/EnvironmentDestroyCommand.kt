package de.solidblocks.cli.commands.environments

import com.github.ajalt.clikt.parameters.options.flag
import com.github.ajalt.clikt.parameters.options.option
import de.solidblocks.cli.commands.BaseCloudEnvironmentCommand
import de.solidblocks.cloud.SolidblocksAppplicationContext

class EnvironmentDestroyCommand :
    BaseCloudEnvironmentCommand(name = "destroy", help = "destroy environment") {

    val destroyVolumes by option("--destroy-volumes").flag(default = false)

    override fun run() {
        val context = SolidblocksAppplicationContext(solidblocksDatabaseUrl)
        context.createCloudProvisioner(cloud, environment).destroy(destroyVolumes)
    }
}
