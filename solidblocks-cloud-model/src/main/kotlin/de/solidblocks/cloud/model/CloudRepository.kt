package de.solidblocks.cloud.model

import de.solidblocks.cloud.model.model.CloudConfigValue
import de.solidblocks.cloud.model.model.CloudModel
import de.solidblocks.config.db.tables.references.CLOUDS
import de.solidblocks.config.db.tables.references.CONFIGURATION_VALUES
import org.jooq.DSLContext
import java.util.*

class CloudRepository(dsl: DSLContext) : BaseRepository(dsl) {

    fun createCloud(name: String, rootDomain: String, configValues: List<CloudConfigValue> = emptyList()): CloudModel {
        logger.info { "creating cloud '$name'" }

        val id = UUID.randomUUID()
        dsl.insertInto(CLOUDS)
            .columns(
                CLOUDS.ID,
                CLOUDS.NAME,
                CLOUDS.DELETED,
            )
            .values(id, name, false).execute()

        setConfiguration(CloudId(id), CloudModel.ROOT_DOMAIN_KEY, rootDomain)

        configValues.forEach {
            setConfiguration(CloudId(id), it.name, it.value)
        }

        return getCloud(name)!!
    }

    fun hasCloud(name: String): Boolean {
        return dsl.fetchCount(CLOUDS, CLOUDS.NAME.eq(name).and(CLOUDS.DELETED.isFalse)) == 1
    }

    fun listClouds(name: String? = null): List<CloudModel> {
        val latest = latestConfigurationValues(CONFIGURATION_VALUES.CLOUD)

        val clouds = CLOUDS.`as`("clouds")

        var condition = clouds.DELETED.isFalse

        if (name != null) {
            condition = condition.and(clouds.NAME.eq(name))
        }

        return dsl.selectFrom(clouds.leftJoin(latest).on(clouds.ID.eq(latest.field(CONFIGURATION_VALUES.CLOUD))))
            .where(condition)
            .fetchGroups(
                { it.into(clouds) }, { it.into(latest) }
            ).map {
                CloudModel(
                    id = it.key.id!!,
                    name = it.key.name!!,
                    rootDomain = it.value.configValue(CloudModel.ROOT_DOMAIN_KEY).value,
                    it.value.map {
                        CloudConfigValue(
                            it.getValue(CONFIGURATION_VALUES.NAME)!!,
                            it.getValue(CONFIGURATION_VALUES.CONFIG_VALUE)!!,
                            it.getValue(CONFIGURATION_VALUES.VERSION)!!
                        )
                    }
                )
            }
    }

    fun getCloud(name: String): CloudModel {
        return listClouds(name).first()
    }
}
