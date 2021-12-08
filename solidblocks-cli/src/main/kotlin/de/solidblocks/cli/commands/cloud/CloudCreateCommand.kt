package de.solidblocks.cli.commands.cloud

import com.github.ajalt.clikt.parameters.options.option
import com.github.ajalt.clikt.parameters.options.required
import de.solidblocks.cli.commands.BaseCloudDbCommand
import de.solidblocks.cloud.config.CloudConfigurationManager

class CloudCreateCommand :
    BaseCloudDbCommand(name = "create", help = "create a new cloud") {

    val cloud: String by option(help = "name of the cloud").required()

    val domain: String by option(help = "root domain for the cloud").required()

    override fun run() {
        val configurationManager = CloudConfigurationManager(solidblocksDatabase().dsl)
        configurationManager.createCloud(cloud, domain)
    }
}
