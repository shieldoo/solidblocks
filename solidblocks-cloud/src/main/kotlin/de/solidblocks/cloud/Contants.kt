package de.solidblocks.cloud

import de.solidblocks.base.Constants.LABEL_PREFIX
import de.solidblocks.cloud.config.model.CloudConfiguration
import de.solidblocks.cloud.config.model.CloudEnvironmentConfiguration
import de.solidblocks.cloud.config.model.TenantConfiguration

object Contants {

    fun cloudId(environment: CloudEnvironmentConfiguration) = "${environment.cloud.name}-${environment.name}"

    fun pkiMountName(environment: CloudEnvironmentConfiguration) = "${cloudId(environment)}-pki"

    fun kvMountName(environment: CloudEnvironmentConfiguration) = "${cloudId(environment)}-kv"

    fun hostSshMountName(environment: CloudEnvironmentConfiguration) = "${cloudId(environment)}-host-ssh"

    fun userSshMountName(environment: CloudEnvironmentConfiguration) = "${cloudId(environment)}-user-ssh"

    fun networkName(environment: CloudEnvironmentConfiguration) = cloudId(environment)

    fun networkName(tenant: TenantConfiguration) = "${tenant.environment.cloud.name}-${cloudId(tenant.environment)}"

    fun defaultLabels(role: Role) = mapOf("$LABEL_PREFIX/role" to role.toString())

    fun defaultLabels(cloud: CloudConfiguration, role: Role) = defaultLabels(role) + mapOf("$LABEL_PREFIX/cloud" to cloud.name)

    fun defaultLabels(environment: CloudEnvironmentConfiguration, role: Role) = mapOf("$LABEL_PREFIX/environment" to environment.name) + defaultLabels(environment.cloud, role)

    fun defaultLabels(tenant: TenantConfiguration, role: Role) = mapOf("$LABEL_PREFIX/tenant" to tenant.name) + defaultLabels(tenant.environment, role)
}
