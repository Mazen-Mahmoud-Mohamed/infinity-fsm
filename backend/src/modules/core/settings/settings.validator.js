import { body } from 'express-validator';



export const updateOrganizationSettingsValidator = [

  body('name').optional().isString().trim().notEmpty().isLength({ max: 200 }),

  body('contactEmail').optional({ nullable: true }).isEmail().normalizeEmail(),

  body('contactPhone')

    .optional({ nullable: true })

    .isString()

    .trim()

    .isLength({ max: 40 }),

  body('timezone').optional().isString().trim().isLength({ max: 80 }),

  body('address').optional({ nullable: true }).isObject(),

  body('address.line1').optional({ nullable: true }).isString().trim().isLength({ max: 200 }),

  body('address.line2').optional({ nullable: true }).isString().trim().isLength({ max: 200 }),

  body('address.city').optional({ nullable: true }).isString().trim().isLength({ max: 120 }),

  body('address.governorate')

    .optional({ nullable: true })

    .isString()

    .trim()

    .isLength({ max: 120 }),

  body('address.country').optional({ nullable: true }).isString().trim().isLength({ max: 120 }),

  body('address.postalCode')

    .optional({ nullable: true })

    .isString()

    .trim()

    .isLength({ max: 40 }),

  body('workingHours').optional().isObject(),

  body('workingHours.start')

    .optional()

    .matches(/^([01]\d|2[0-3]):[0-5]\d$/)

    .withMessage('workingHours.start must be HH:mm'),

  body('workingHours.end')

    .optional()

    .matches(/^([01]\d|2[0-3]):[0-5]\d$/)

    .withMessage('workingHours.end must be HH:mm'),

  body('workingHours.timezone').optional().isString().trim().isLength({ max: 80 }),

];



export const updateOvertimeSettingsValidator = [

  body('voiceMaxDurationSeconds')

    .optional()

    .isInt()

    .withMessage('voiceMaxDurationSeconds must be an integer')

    .isIn([120, 300, 600, 900, 1200])

    .withMessage(

      'voiceMaxDurationSeconds must be one of: 120, 300, 600, 900, 1200'

    ),

  body('voiceRecordingQuality')

    .optional()

    .isString()

    .trim()

    .isIn(['high', 'medium', 'low'])

    .withMessage('voiceRecordingQuality must be one of: high, medium, low'),

  body('maxPhotoSize')

    .optional()

    .custom((value) => {

      if (value === 'original') {

        return true;

      }

      const n = Number(value);

      return [1, 2, 5].includes(n);

    })

    .withMessage('maxPhotoSize must be one of: 1, 2, 5, original'),

  body('uploadPolicy')

    .optional()

    .isString()

    .trim()

    .isIn(['immediately', 'wifi_preferred', 'wifi_only', 'manual', 'ask_every_time'])

    .withMessage(

      'uploadPolicy must be one of: immediately, wifi_preferred, wifi_only, manual, ask_every_time'

    ),

  body('configurationPreset')

    .optional()

    .isString()

    .trim()

    .isIn(['office', 'field_service', 'heavy_maintenance', 'custom'])

    .withMessage(

      'configurationPreset must be one of: office, field_service, heavy_maintenance, custom'

    ),

  body('restoreDefaults')

    .optional()

    .isBoolean()

    .withMessage('restoreDefaults must be a boolean'),

];



export const updateTechnicianInterfaceSettingsValidator = [

  body('overtime')

    .optional()

    .isBoolean()

    .withMessage('overtime must be a boolean'),

  body('workOrders')

    .optional()

    .isBoolean()

    .withMessage('workOrders must be a boolean'),

  body('attendance')

    .optional()

    .isBoolean()

    .withMessage('attendance must be a boolean'),

  body('profile')

    .optional()

    .isBoolean()

    .withMessage('profile must be a boolean'),

];

