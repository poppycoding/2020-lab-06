-- ----------------------------
-- 3、shiro相关表格
-- ----------------------------
-- 系统资源权限
CREATE TABLE IF NOT EXISTS `sys_permission` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `perm_type` int(2) COMMENT '1:页面权限  2:数据权限',
  `parent_id` bigint COMMENT '父菜单ID，一级菜单为0',
  `name` varchar(50) COMMENT '菜单名称',
  `url` varchar(200) COMMENT '菜单URL',
  `perms` varchar(500) COMMENT '授权(多个用逗号分隔，如：user:list,user:create)',
  `type` int(2) COMMENT '类型   0：目录   1：菜单   2：按钮',
  `icon` varchar(200)  COMMENT '图标',
  `order_num` int(2) COMMENT '排序',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='资源权限管理';

INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (1, 1, 0, '数据管理', NULL, '', 0, './assets/images/sidebar/icon-metadata.svg', 0);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (2, 1, 0, '数据分析', NULL, NULL, 0, './assets/images/sidebar/icon-masterdata.svg', 1);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (3, 1, 0, '系统管理', NULL, NULL, 0, './assets/images/sidebar/icon-system.svg', 2);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (4, 1, 0, '数据地图', '/graph', NULL, 0, './assets/images/sidebar/icon-masterdata.svg', 3);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (5, 1, 1, '元数据采集', '/gather', '', 1, NULL, 4);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (6, 1, 1, '元数据管理', '/management', '', 1, NULL, 5);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (7, 1, 2, '影响分析', '/impact', NULL, 1, NULL, 6);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (8, 1, 2, '血缘分析', '/blood', NULL, 1, NULL, 7);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (9, 1, 3, '用户管理', '/system/user', NULL, 1, NULL, 8);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (10, 1, 3, '角色权限管理', '/system/authority', NULL, 1, NULL, 9);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (11, 1, 3, '字典管理', '/dictionaries', NULL, 1, NULL, 10);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (12, 1, 4, '地图', '/graph', NULL, 1, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (13, 1, 5, '显示', '', 'meta:job:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (14, 1, 5, '采集', '', 'meta:job:list,meta:job:collect', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (15, 1, 5, '导入', '', 'meta:excel:import', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (16, 1, 5, '导出', '', 'meta:excel:export', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (17, 1, 6, '显示', '', 'meta:data:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (18, 1, 6, '查看', '', 'meta:data:list,meta:data:info', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (19, 1, 6, '编辑', '', 'meta:data:list,meta:data:update', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (20, 1, 6, '新增', '', 'meta:data:list,meta:data:info,meta:data:save', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (21, 1, 6, '删除', '', 'meta:data:list,meta:data:delete', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (22, 1, 7, '显示', '', 'meta:impact:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (23, 1, 7, '查看', '', 'meta:impact:list,meta:data:info', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (24, 1, 8, '显示', '', 'meta:lineage:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (25, 1, 8, '查看', '', 'meta:lineage:list,meta:data:info', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (26, 1, 9, '显示', '', 'sys:user:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (27, 1, 9, '重置密码', '', 'sys:user:pwd,sys:user:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (28, 1, 9, '新增', '', 'sys:user:save,sys:role:info,sys:user:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (29, 1, 9, '删除', '', 'sys:user:delete,sys:user:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (30, 1, 9, '编辑', '', 'sys:user:update,sys:role:info,sys:user:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (31, 1, 10, '删除', '', 'sys:role:delete,sys:role:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (32, 1, 10, '查看', '', 'sys:role:info,sys:perm:list,sys:role:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (33, 1, 10, '编辑', '', 'sys:role:update,sys:perm:list,sys:role:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (34, 1, 10, '新增', '', 'sys:role:save,sys:perm:list,sys:role:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (35, 1, 10, '显示', '', 'sys:role:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (36, 1, 11, '显示', '', 'sys:dict:list', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (37, 1, 11, '查看', '', 'sys:dict:list,sys:dict:info', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (38, 1, 11, '新增', '', 'sys:dict:list,sys:dict:save', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (39, 1, 11, '编辑', '', 'sys:dict:list,sys:dict:update', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (40, 1, 11, '删除', '', 'sys:dict:list,sys:dict:delete', 2, NULL, NULL);
INSERT INTO `sys_permission`(`id`, `perm_type`, `parent_id`, `name`, `url`, `perms`, `type`, `icon`, `order_num`) VALUES (41, 1, 12, '显示', '', 'meta:map:data', 2, NULL, NULL);


-- 系统用户
CREATE TABLE IF NOT EXISTS `sys_user` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(50) binary NOT NULL COMMENT '用户名',
  `password` varchar(100) COMMENT '密码',
  `role_name` varchar(10) COMMENT '用户角色名称',
  `salt` varchar(20) COMMENT '盐',
  `email` varchar(100) COMMENT '邮箱',
  `phone` varchar(13) COMMENT '手机号',
  `department` varchar(100) COMMENT '部门',
  `status` tinyint DEFAULT 1 COMMENT '状态  0：禁用   1：正常',
  `remark` varchar(200) COMMENT '备注',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_at` bigint(13) DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_at` bigint(13) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE INDEX (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='系统用户';

INSERT INTO  `sys_user`(`id`, `username`, `password`, `role_name`, `salt`, `email`, `phone`, `department`, `status`, `remark`, `create_by`, `create_at`, `update_by`, `update_at`) VALUES (1, 'admin', '0445e39c6be4b7f7aa7aa8445c217a6dd78e48e84b2898fa95a09a2f409a0e1a', '超级管理员', 'YzcmCZNvbXocrsz9dm8e', 'admin@qq.com', '13666666666', '大数据部门', 1, '超级管理员', '', NULL, 'admin', 1541039697075);


-- 系统用户Token
CREATE TABLE IF NOT EXISTS `sys_token` (
  `user_id` bigint(20) NOT NULL,
  `token` varchar(100) NOT NULL COMMENT 'token',
  `expire_time` bigint(20) DEFAULT NULL COMMENT '过期时间',
  `update_time` bigint(20) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `token` (`token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='系统用户Token';

-- 角色
CREATE TABLE IF NOT EXISTS `sys_role` (
  `id` bigint(13) NOT NULL AUTO_INCREMENT,
  `role_name` varchar(100) binary COMMENT '角色名称',
  `status` tinyint DEFAULT 1 COMMENT '状态  0：禁用   1：正常',
  `remark` varchar(100) COMMENT '备注',
  `create_by` varchar(64) DEFAULT '' COMMENT '创建者',
  `create_at` bigint(13) DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(64) DEFAULT '' COMMENT '更新者',
  `update_at` bigint(13) DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='角色';

INSERT INTO  `sys_role`(`id`, `role_name`, `status`, `remark`, `create_by`, `create_at`, `update_by`, `update_at`) VALUES (1, '超级管理员', 1, '所有权限', 'admin', 1540274121583, 'admin', 1541239894413);


-- 部门
CREATE TABLE IF NOT EXISTS `sys_department` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `department` varchar(25) COMMENT '部门名称',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='部门字典';

INSERT INTO  `sys_department`(`id`, `department`) VALUES (1, '大数据部门');
INSERT INTO  `sys_department`(`id`, `department`) VALUES (2, '测试部门');
INSERT INTO  `sys_department`(`id`, `department`) VALUES (3, '运维部门');
INSERT INTO  `sys_department`(`id`, `department`) VALUES (4, '行政部门');
INSERT INTO  `sys_department`(`id`, `department`) VALUES (5, '销售部门');


-- 用户与角色对应关系
CREATE TABLE IF NOT EXISTS `sys_user_role` (
  `id` bigint(13) NOT NULL AUTO_INCREMENT,
  `user_id` bigint(13) NOT NULL COMMENT '用户ID',
  `role_id` bigint(13) NOT NULL COMMENT '角色ID',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='用户与角色对应关系';

INSERT INTO  `sys_user_role`(`id`, `user_id`, `role_id`) VALUES (1, 1, 1);


-- 角色与权限对应关系
CREATE TABLE IF NOT EXISTS `sys_role_permission` (
  `id` bigint(13) NOT NULL AUTO_INCREMENT,
  `role_id` bigint(13) COMMENT '角色ID',
  `permission_id` bigint(13) COMMENT '权限ID',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='角色与权限对应关系';

INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (1, 1, 1);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (2, 1, 2);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (3, 1, 3);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (4, 1, 4);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (5, 1, 5);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (6, 1, 6);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (7, 1, 7);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (8, 1, 8);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (9, 1, 9);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (10, 1, 10);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (11, 1, 11);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (12, 1, 12);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (13, 1, 13);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (14, 1, 14);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (15, 1, 15);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (16, 1, 16);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (17, 1, 17);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (18, 1, 18);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (19, 1, 19);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (20, 1, 20);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (21, 1, 21);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (22, 1, 22);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (23, 1, 23);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (24, 1, 24);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (25, 1, 25);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (26, 1, 26);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (27, 1, 27);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (28, 1, 28);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (29, 1, 29);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (30, 1, 30);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (31, 1, 31);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (32, 1, 32);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (33, 1, 33);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (34, 1, 34);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (35, 1, 35);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (36, 1, 36);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (37, 1, 37);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (38, 1, 38);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (39, 1, 39);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (40, 1, 40);
INSERT INTO  `sys_role_permission`(`id`, `role_id`, `permission_id`) VALUES (41, 1, 41);
