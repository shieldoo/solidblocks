package de.solidblocks.provisioner.hetzner

import de.solidblocks.api.resources.infrastructure.IInfrastructureResourceProvisioner
import de.solidblocks.api.resources.infrastructure.IResourceLookupProvider
import de.solidblocks.api.resources.infrastructure.InfrastructureProvisioner
import de.solidblocks.base.ProvisionerRegistry
import de.solidblocks.cloud.model.ModelConstants.HETZNER_CLOUD_API_TOKEN_RW_KEY
import de.solidblocks.cloud.model.ModelConstants.HETZNER_DNS_API_TOKEN_RW_KEY
import de.solidblocks.cloud.model.model.EnvironmentModel
import de.solidblocks.core.IResourceLookup
import de.solidblocks.provisioner.hetzner.cloud.floatingip.HetznerFloatingIpAssignmentResourceProvisioner
import de.solidblocks.provisioner.hetzner.cloud.floatingip.HetznerFloatingIpResourceProvisioner
import de.solidblocks.provisioner.hetzner.cloud.network.HetznerNetworkResourceProvisioner
import de.solidblocks.provisioner.hetzner.cloud.network.HetznerSubnetResourceProvisioner
import de.solidblocks.provisioner.hetzner.cloud.server.HetznerServerResourceProvisioner
import de.solidblocks.provisioner.hetzner.cloud.server.UserDataResourceLookupProvider
import de.solidblocks.provisioner.hetzner.cloud.ssh.HetznerSshResourceProvisioner
import de.solidblocks.provisioner.hetzner.cloud.volume.HetznerVolumeResourceProvisioner
import de.solidblocks.provisioner.hetzner.dns.record.HetznerDnsRecordResourceProvisioner
import de.solidblocks.provisioner.hetzner.dns.zone.HetznerDnsZoneResourceProvisioner
import io.pelle.hetzner.HetznerDnsAPI
import me.tomsdevsn.hetznercloud.HetznerCloudAPI

object Hetzner {

    fun createCloudApi(environmentConfiguration: EnvironmentModel): HetznerCloudAPI {
        return HetznerCloudAPI(environmentConfiguration.getConfigValue(HETZNER_CLOUD_API_TOKEN_RW_KEY))
    }

    fun createDnsApi(environmentConfiguration: EnvironmentModel): HetznerDnsAPI {
        return HetznerDnsAPI(environmentConfiguration.getConfigValue(HETZNER_DNS_API_TOKEN_RW_KEY))
    }

    fun registerLookups(
        provisionerRegistry: ProvisionerRegistry,
        provisioner: InfrastructureProvisioner
    ) {
        provisionerRegistry.addLookupProvider(
            UserDataResourceLookupProvider(provisioner) as IResourceLookupProvider<IResourceLookup<Any>, Any>
        )
    }

    fun registerProvisioners(
        provisionerRegistry: ProvisionerRegistry,
        environmentConfiguration: EnvironmentModel,
        provisioner: InfrastructureProvisioner
    ) {

        provisionerRegistry.addLookupProvider(
            HetznerDnsZoneResourceProvisioner(
                createDnsApi(environmentConfiguration),
            ) as IResourceLookupProvider<IResourceLookup<Any>, Any>
        )

        provisionerRegistry.addProvisioner(
            HetznerDnsRecordResourceProvisioner(
                createDnsApi(environmentConfiguration),
                provisioner
            ) as IInfrastructureResourceProvisioner<Any, Any>
        )

        provisionerRegistry.addProvisioner(
            HetznerSubnetResourceProvisioner(
                createCloudApi(environmentConfiguration),
                provisioner
            ) as IInfrastructureResourceProvisioner<Any, Any>
        )

        provisionerRegistry.addProvisioner(
            HetznerNetworkResourceProvisioner(
                createCloudApi(environmentConfiguration),
            ) as IInfrastructureResourceProvisioner<Any, Any>
        )

        provisionerRegistry.addProvisioner(
            HetznerServerResourceProvisioner(
                createCloudApi(environmentConfiguration),
                provisioner
            ) as IInfrastructureResourceProvisioner<Any, Any>
        )

        provisionerRegistry.addProvisioner(
            HetznerSshResourceProvisioner(
                createCloudApi(environmentConfiguration),
            ) as IInfrastructureResourceProvisioner<Any, Any>
        )

        provisionerRegistry.addProvisioner(
            HetznerVolumeResourceProvisioner(
                createCloudApi(environmentConfiguration),
            ) as IInfrastructureResourceProvisioner<Any, Any>
        )

        provisionerRegistry.addProvisioner(
            HetznerFloatingIpAssignmentResourceProvisioner(
                createCloudApi(environmentConfiguration),
                provisioner
            ) as IInfrastructureResourceProvisioner<Any, Any>
        )

        provisionerRegistry.addProvisioner(
            HetznerFloatingIpResourceProvisioner(
                createCloudApi(environmentConfiguration)
            ) as IInfrastructureResourceProvisioner<Any, Any>
        )
    }
}
